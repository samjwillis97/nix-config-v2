/**
 * Workflow Gate Extension
 *
 * Enforces the brainstorm → plan → implement → review → verify workflow.
 * Uses a cheap LLM call to classify task intent (feature/bug/small/question).
 * Tracks current phase and blocks premature tool calls.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import { complete } from "@earendil-works/pi-ai";

type WorkflowPhase =
	| "idle"
	| "brainstorm"
	| "plan"
	| "implement"
	| "review"
	| "verify"
	| "complete";
type TaskType = "feature" | "bug" | "small" | "question" | "unknown";

interface WorkflowState {
	phase: WorkflowPhase;
	taskDescription: string;
	phaseHistory: Array<{ phase: WorkflowPhase; timestamp: number }>;
	gateEnabled: boolean;
}

const PHASE_ICONS: Record<WorkflowPhase, string> = {
	idle: "💤",
	brainstorm: "💡",
	plan: "📋",
	implement: "🔨",
	review: "🔍",
	verify: "✅",
	complete: "🎉",
};

const PHASE_ORDER: WorkflowPhase[] = [
	"brainstorm",
	"plan",
	"implement",
	"review",
	"verify",
	"complete",
];

const CLASSIFY_PROMPT = `Classify the user's message into exactly one category. Reply with ONLY the category name, nothing else.

You may receive conversation history before the current message. Consider the FULL SCOPE of work discussed, not just the latest message. If previous messages discussed significant changes and the current message asks to implement, plan, or action them, classify based on the scope of ALL the changes, not just the transition message.

Categories:
- feature: New functionality, significant changes, architecture decisions, refactoring, redesigning, adding capabilities. Things that benefit from design exploration before implementation.
- bug: Bug reports, errors, crashes, things not working, debugging, fixing broken behaviour.
- small: Minor/mechanical changes — config tweaks, renaming, typo fixes, doc updates, git operations (commits, merges, pushes, branching), dependency updates, formatting, style changes.
- question: Questions about the codebase, explanations, "how does X work", "what does Y do", reading/exploring code without changes.

Reply with one word: feature, bug, small, or question.`;

/**
 * Build a condensed summary of conversation history for the classifier.
 * Extracts the last few user/assistant exchanges so the classifier can
 * understand the full scope of work, not just the latest message.
 */
function buildConversationContext(sessionManager: {
	getEntries: () => any[];
}): string | undefined {
	const entries = sessionManager.getEntries();
	if (entries.length === 0) return undefined;

	const snippets: string[] = [];
	let totalLen = 0;
	const MAX_CONTEXT = 800;
	const MAX_SNIPPET = 150;

	// Walk entries in order, collect last user/assistant text exchanges
	const exchanges: Array<{ role: string; text: string }> = [];
	for (const entry of entries) {
		if (entry.type !== "message" || !entry.message) continue;
		const msg = entry.message;

		if (msg.role === "user") {
			const text =
				typeof msg.content === "string"
					? msg.content
					: (msg.content || [])
							.filter(
								(c: any): c is { type: "text"; text: string } =>
									c.type === "text",
							)
							.map((c: any) => c.text)
							.join(" ");
			if (text.trim()) exchanges.push({ role: "user", text: text.trim() });
		} else if (msg.role === "assistant") {
			const text = (msg.content || [])
				.filter(
					(c: any): c is { type: "text"; text: string } => c.type === "text",
				)
				.map((c: any) => c.text)
				.join(" ");
			if (text.trim()) exchanges.push({ role: "assistant", text: text.trim() });
		}
	}

	// Take the last 6 exchanges (up to 3 user + 3 assistant)
	const recent = exchanges.slice(-6);
	if (recent.length === 0) return undefined;

	for (const ex of recent) {
		const truncated =
			ex.text.length > MAX_SNIPPET
				? ex.text.slice(0, MAX_SNIPPET) + "..."
				: ex.text;
		const line =
			ex.role === "user" ? `- User: ${truncated}` : `- Assistant: ${truncated}`;
		if (totalLen + line.length > MAX_CONTEXT) break;
		snippets.push(line);
		totalLen += line.length;
	}

	if (snippets.length === 0) return undefined;
	return `Conversation so far:\n${snippets.join("\n")}\n\nCurrent message:`;
}

interface ClassifyResult {
	taskType: TaskType;
	model?: string;
	error?: string;
}

async function classifyWithLLM(
	prompt: string,
	ctx: { model: any; modelRegistry: any },
	contextPrefix?: string,
): Promise<ClassifyResult> {
	// Use modelRegistry.find() instead of getModel() — the registry applies
	// OAuth baseUrl overrides (e.g., Copilot for Business proxy-ep), while
	// getModel() returns static built-in definitions with wrong baseUrl.
	const candidates = [
		ctx.modelRegistry.find("github-copilot", "claude-haiku-4.5"),
		ctx.modelRegistry.find("anthropic", "claude-haiku-4-5"),
		ctx.modelRegistry.find("github-copilot", "gpt-4o-mini"),
		ctx.modelRegistry.find("openai", "gpt-4o-mini"),
		ctx.model,
	].filter((m) => m != null);

	let classifyModel = ctx.model;
	for (const candidate of candidates) {
		const auth = await ctx.modelRegistry.getApiKeyAndHeaders(candidate);
		if (auth.ok && auth.apiKey) {
			classifyModel = candidate;
			break;
		}
	}

	if (!classifyModel) {
		return {
			taskType: "unknown",
			error:
				"No classifier model available (no model with valid API key found)",
		};
	}

	const modelLabel = `${classifyModel.provider}/${classifyModel.id}`;
	const auth = await ctx.modelRegistry.getApiKeyAndHeaders(classifyModel);
	if (!auth.ok || !auth.apiKey) {
		return {
			taskType: "unknown",
			model: modelLabel,
			error: `No API key for ${modelLabel}`,
		};
	}

	try {
		const response = await complete(
			classifyModel,
			{
				systemPrompt: CLASSIFY_PROMPT,
				messages: [
					{
						role: "user",
						content: [
							{
								type: "text",
								text: contextPrefix
									? `${contextPrefix}\n${prompt.slice(0, 500)}`
									: prompt.slice(0, 500),
							},
						],
						timestamp: Date.now(),
					},
				],
			},
			{ apiKey: auth.apiKey, headers: auth.headers },
		);

		const result = response.content
			.filter((c): c is { type: "text"; text: string } => c.type === "text")
			.map((c) => c.text)
			.join("")
			.trim()
			.toLowerCase();

		const valid: TaskType[] = ["feature", "bug", "small", "question"];
		if (valid.includes(result as TaskType))
			return { taskType: result as TaskType, model: modelLabel };

		// Handle partial matches (model might say "feature." or "it's a feature")
		for (const t of valid) {
			if (result.includes(t)) return { taskType: t, model: modelLabel };
		}

		return {
			taskType: "unknown",
			model: modelLabel,
			error: `Unexpected classifier response: "${result}"`,
		};
	} catch (err: any) {
		const message = err?.message || String(err);
		return {
			taskType: "unknown",
			model: modelLabel,
			error: `Classification failed: ${message}`,
		};
	}
}

export default function (pi: ExtensionAPI) {
	let state: WorkflowState = {
		phase: "idle",
		taskDescription: "",
		phaseHistory: [],
		gateEnabled: true,
	};

	// Pending classification promise — tool_call can await this for write/edit gating
	let pendingClassification: Promise<TaskType> | null = null;

	function setPhase(phase: WorkflowPhase) {
		state.phase = phase;
		state.phaseHistory.push({ phase, timestamp: Date.now() });
		pi.appendEntry("superpowers:workflow", {
			phase,
			taskDescription: state.taskDescription,
		});
	}

	function updateStatus(ctx: {
		ui: { setWidget: (id: string, lines: string[], options?: any) => void };
	}) {
		const icon = PHASE_ICONS[state.phase];
		const gate = state.gateEnabled ? "🔒" : "🔓";
		ctx.ui.setWidget("workflow", [`${icon} ${state.phase} ${gate}`], {
			placement: "belowEditor",
		});
	}

	/** Apply classification result: update phase, send steering message if needed */
	function applyClassification(
		taskType: TaskType,
		ctx: {
			ui: { setWidget: (id: string, lines: string[], options?: any) => void };
		},
	) {
		if (taskType === "feature") {
			setPhase("brainstorm");
			updateStatus(ctx);
			pi.sendMessage(
				{
					customType: "superpowers:workflow-hint",
					content: [
						"🔒 WORKFLOW GATE: This looks like a new feature/significant change.",
						"Start with brainstorming — explore approaches and tradeoffs before planning.",
						"Load the brainstorming skill, or discuss the design first.",
						"Use /advance when ready to move to the next phase.",
					].join("\n"),
					display: true,
				},
				{ deliverAs: "steer" },
			);
		} else if (taskType === "bug") {
			setPhase("implement");
			updateStatus(ctx);
			pi.sendMessage(
				{
					customType: "superpowers:workflow-hint",
					content: [
						"🔧 WORKFLOW: Bug fix detected.",
						"Investigate the root cause first — don't guess at fixes.",
						"Load the systematic-debugging skill.",
						"After fixing, verify with tests.",
					].join("\n"),
					display: true,
				},
				{ deliverAs: "steer" },
			);
		} else if (taskType === "small") {
			setPhase("implement");
			updateStatus(ctx);
		} else {
			// "question" or "unknown" — no workflow phase, let the agent respond freely
			updateStatus(ctx);
		}
	}

	pi.on("session_start", async (_event, ctx) => {
		state = {
			phase: "idle",
			taskDescription: "",
			phaseHistory: [],
			gateEnabled: true,
		};
		pendingClassification = null;

		// Restore state from session
		const entries = ctx.sessionManager.getEntries();
		for (const entry of entries) {
			if (
				entry.type === "custom" &&
				entry.customType === "superpowers:workflow"
			) {
				const data = entry.data as {
					phase: WorkflowPhase;
					taskDescription: string;
				};
				if (data?.phase) {
					state.phase = data.phase;
					state.taskDescription = data.taskDescription || "";
				}
			}
		}

		updateStatus(ctx);
	});

	// Classify task type — fire-and-forget, does NOT block agent startup
	pi.on("before_agent_start", async (event, ctx) => {
		const prompt = event.prompt;
		if (!prompt) return;

		if (state.phase !== "idle" && state.phase !== "complete") return;

		state.taskDescription = prompt;

		// Build conversation context for classification (only if there's history)
		const conversationContext = buildConversationContext(ctx.sessionManager);

		ctx.ui.setWidget("workflow", ["🔍 Classifying task..."], {
			placement: "belowEditor",
		});

		// Start classification in the background — don't await it
		pendingClassification = classifyWithLLM(
			prompt,
			ctx,
			conversationContext,
		).then(({ taskType, model: _model, error }) => {
			if (error) {
				ctx.ui.notify(`⚠️ Workflow gate: ${error}`, "warning");
			}
			applyClassification(taskType, ctx);
			pendingClassification = null;
			return taskType;
		});

		// Return immediately — agent starts without waiting for classification
	});

	// Gate: block write/edit during brainstorm/plan phase.
	// If classification is still pending, await it before deciding.
	pi.on("tool_call", async (event, ctx) => {
		if (!state.gateEnabled) return;

		// Only care about write/edit/subagent for gating
		const isGatedTool =
			isToolCallEventType("write", event) ||
			isToolCallEventType("edit", event) ||
			isToolCallEventType("subagent", event);

		// If classification is still in-flight and this is a gated tool, wait for it
		if (pendingClassification && isGatedTool) {
			await pendingClassification;
		}

		if (state.phase === "brainstorm") {
			if (
				isToolCallEventType("write", event) ||
				isToolCallEventType("edit", event)
			) {
				const path = (event.input as any)?.path || "";

				// Allow writing design docs
				if (
					path.includes("docs/") ||
					path.includes("designs/") ||
					path.includes("plans/")
				) {
					return;
				}

				updateStatus(ctx);
				return {
					block: true,
					reason: [
						"🔒 WORKFLOW GATE: Cannot write/edit code during brainstorming phase.",
						"The design must be discussed and approved first.",
						"Write design docs to docs/specs/ if needed.",
						"Use /advance to move to the planning phase when the design is approved.",
					].join("\n"),
				};
			}

			if (isToolCallEventType("subagent", event)) {
				updateStatus(ctx);
				return {
					block: true,
					reason: [
						"🔒 WORKFLOW GATE: Cannot dispatch subagents during brainstorming phase.",
						"The design must be discussed and approved before delegating implementation work.",
						"Use /advance to move to the next phase when the design is approved.",
					].join("\n"),
				};
			}
		}

		if (state.phase === "plan") {
			if (
				isToolCallEventType("write", event) ||
				isToolCallEventType("edit", event)
			) {
				const path = (event.input as any)?.path || "";

				// Allow writing plan docs
				if (
					path.includes("docs/") ||
					path.includes("plans/") ||
					path.includes("designs/")
				) {
					return;
				}

				updateStatus(ctx);
				return {
					block: true,
					reason: [
						"🔒 WORKFLOW GATE: Cannot write/edit code during planning phase.",
						"Complete the plan first. Write plan docs to docs/plans/ or use the plan tool.",
						"Use /advance to move to the implementation phase.",
					].join("\n"),
				};
			}

			if (isToolCallEventType("subagent", event)) {
				updateStatus(ctx);
				return {
					block: true,
					reason: [
						"🔒 WORKFLOW GATE: Cannot dispatch subagents during planning phase.",
						"Complete the plan first using the plan tool.",
						"Use /advance to move to the implementation phase.",
					].join("\n"),
				};
			}
		}
	});

	// /advance - move to next phase
	pi.registerCommand("advance", {
		description: "Advance to the next workflow phase",
		handler: async (_args, ctx) => {
			const currentIndex = PHASE_ORDER.indexOf(state.phase);

			if (state.phase === "idle") {
				ctx.ui.notify(
					"No active workflow. Start by describing a task.",
					"warning",
				);
				return;
			}

			if (currentIndex >= PHASE_ORDER.length - 1) {
				setPhase("idle");
				updateStatus(ctx);
				ctx.ui.notify("Workflow complete! Ready for new tasks.", "info");
				return;
			}

			const nextPhase = PHASE_ORDER[currentIndex + 1];
			setPhase(nextPhase);
			updateStatus(ctx);
			ctx.ui.notify(
				`Advanced to: ${PHASE_ICONS[nextPhase]} ${nextPhase}`,
				"info",
			);

			// Tell the agent to proceed with the new phase
			const phaseInstructions: Record<string, string> = {
				plan: [
					"The design has been approved. Move to planning.",
					"Create a detailed implementation plan using the `plan` tool.",
					"Break the work into small, verifiable steps (2-5 minutes each).",
					"Each step needs: description, file paths, and a verification command.",
					"Load the planning skill for guidance.",
				].join(" "),
				implement: [
					"The plan is complete. Move to implementation.",
					"Execute the plan step by step.",
					"Use subagents to implement each step in isolation.",
					"Update plan status after each step. Do not pause to ask — keep going unless blocked.",
					"Load the executing-plans skill for guidance.",
				].join(" "),
				review: [
					"Implementation is complete. Move to review.",
					"Run a two-stage review: first spec compliance (did we build what was asked?),",
					"then code quality (is it well-built?).",
					"Use /review or dispatch spec-reviewer and reviewer subagents.",
				].join(" "),
				verify: [
					"Review is complete. Move to verification.",
					"Run the full test suite and build. Show the output.",
					"Demonstrate the change works with concrete evidence.",
					"No hedging — show actual results.",
					"Load the verification skill for guidance.",
				].join(" "),
				complete: [
					"Verification passed. The work is complete.",
					"Summarise what was done, files changed, and verification results.",
				].join(" "),
			};

			const instruction = phaseInstructions[nextPhase];
			if (instruction) {
				pi.sendUserMessage(instruction, { deliverAs: "followUp" });
			}
		},
	});

	// /phase - set phase directly
	pi.registerCommand("phase", {
		description:
			"Set workflow phase (brainstorm, plan, implement, review, verify, complete, idle)",
		handler: async (args, ctx) => {
			const phase = args.trim().toLowerCase() as WorkflowPhase;
			const validPhases: WorkflowPhase[] = [
				"idle",
				"brainstorm",
				"plan",
				"implement",
				"review",
				"verify",
				"complete",
			];

			if (!validPhases.includes(phase)) {
				ctx.ui.notify(
					`Invalid phase. Valid: ${validPhases.join(", ")}`,
					"error",
				);
				return;
			}

			setPhase(phase);
			updateStatus(ctx);
			ctx.ui.notify(`Phase set to: ${PHASE_ICONS[phase]} ${phase}`, "info");
		},
	});

	// /gate - toggle gate enforcement
	pi.registerCommand("gate", {
		description: "Toggle workflow gate enforcement on/off",
		handler: async (_args, ctx) => {
			state.gateEnabled = !state.gateEnabled;
			updateStatus(ctx);
			ctx.ui.notify(
				state.gateEnabled
					? "🔒 Workflow gate ENABLED — write/edit blocked in brainstorm/plan phases"
					: "🔓 Workflow gate DISABLED — all tool calls allowed",
				"info",
			);
		},
	});
}
