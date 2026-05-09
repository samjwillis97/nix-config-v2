/**
 * Workflow Gate Extension
 *
 * Enforces the brainstorm → plan → implement → review → verify workflow.
 * Tracks current phase and can block premature tool calls.
 * Shows current phase in status line.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

type WorkflowPhase = "idle" | "brainstorm" | "plan" | "implement" | "review" | "verify" | "complete";

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

const PHASE_ORDER: WorkflowPhase[] = ["brainstorm", "plan", "implement", "review", "verify", "complete"];

// Patterns that suggest the user is asking for something that should go through the full workflow
const FEATURE_PATTERNS = [
	/\b(?:add|create|build|implement|develop|make|design)\s+(?:a|an|the|new)?\s*\w+/i,
	/\b(?:new\s+feature|feature\s+request)\b/i,
	/\b(?:refactor|redesign|rearchitect|rewrite)\b/i,
	/\bI\s+want\s+(?:to|a|an)\b/i,
	/\b(?:can\s+you|could\s+you|please)\s+(?:add|create|build|implement|make)\b/i,
];

const BUG_PATTERNS = [
	/\b(?:bug|broken|doesn'?t\s+work|not\s+working|error|crash|fail|issue)\b/i,
	/\b(?:fix|debug|troubleshoot|investigate)\b/i,
];

const SMALL_CHANGE_PATTERNS = [
	/\b(?:rename|update\s+(?:the\s+)?(?:version|readme|docs?|comment|typo))\b/i,
	/\b(?:change\s+(?:the\s+)?(?:name|label|text|color|style))\b/i,
	/\b(?:remove\s+(?:the\s+)?(?:unused|dead|old))\b/i,
];

function detectTaskType(input: string): "feature" | "bug" | "small" | "unknown" {
	if (SMALL_CHANGE_PATTERNS.some((p) => p.test(input))) return "small";
	if (FEATURE_PATTERNS.some((p) => p.test(input))) return "feature";
	if (BUG_PATTERNS.some((p) => p.test(input))) return "bug";
	return "unknown";
}

export default function (pi: ExtensionAPI) {
	let state: WorkflowState = {
		phase: "idle",
		taskDescription: "",
		phaseHistory: [],
		gateEnabled: true,
	};

	function setPhase(phase: WorkflowPhase) {
		state.phase = phase;
		state.phaseHistory.push({ phase, timestamp: Date.now() });
		pi.appendEntry("superpowers:workflow", { phase, taskDescription: state.taskDescription });
	}

	function updateStatus(ctx: { ui: { setWidget: (id: string, lines: string[], options?: any) => void } }) {
		const icon = PHASE_ICONS[state.phase];
		const gate = state.gateEnabled ? "🔒" : "🔓";
		ctx.ui.setWidget("workflow", [`${icon} ${state.phase} ${gate}`], { placement: "belowEditor" });
	}

	pi.on("session_start", async (_event, ctx) => {
		state = {
			phase: "idle",
			taskDescription: "",
			phaseHistory: [],
			gateEnabled: true,
		};

		// Restore state from session
		const entries = ctx.sessionManager.getEntries();
		for (const entry of entries) {
			if (entry.type === "custom" && entry.customType === "superpowers:workflow") {
				const data = entry.data as { phase: WorkflowPhase; taskDescription: string };
				if (data?.phase) {
					state.phase = data.phase;
					state.taskDescription = data.taskDescription || "";
				}
			}
		}

		updateStatus(ctx);
	});

	// Detect task type from user input and suggest workflow
	pi.on("before_agent_start", async (event, ctx) => {
		const prompt = event.prompt;
		if (!prompt) return;

		const taskType = detectTaskType(prompt);

		if (state.phase === "idle" || state.phase === "complete") {
			state.taskDescription = prompt;

			if (taskType === "feature") {
				setPhase("brainstorm");
				updateStatus(ctx);
				return {
					message: {
						customType: "superpowers:workflow-hint",
						content: [
							"🔒 WORKFLOW GATE: This looks like a new feature/significant change.",
							"Start with brainstorming — explore approaches and tradeoffs before planning.",
							"Load /skill:brainstorming if available, or discuss the design first.",
							"Use /advance when ready to move to the next phase.",
						].join("\n"),
						display: true,
					},
				};
			}

			if (taskType === "bug") {
				setPhase("implement"); // Bugs go straight to investigate+fix
				updateStatus(ctx);
				return {
					message: {
						customType: "superpowers:workflow-hint",
						content: [
							"🔧 WORKFLOW: Bug fix detected.",
							"Investigate the root cause first — don't guess at fixes.",
							"Load /skill:systematic-debugging if available.",
							"After fixing, verify with tests.",
						].join("\n"),
						display: true,
					},
				};
			}

			if (taskType === "small") {
				setPhase("implement");
				updateStatus(ctx);
				// Small changes skip brainstorm/plan but still need verification
			}
		}
	});

	// Gate: block write/edit during brainstorm phase
	pi.on("tool_call", async (event, ctx) => {
		if (!state.gateEnabled) return;

		if (state.phase === "brainstorm") {
			if (isToolCallEventType("write", event) || isToolCallEventType("edit", event)) {
				const path = (event.input as any)?.path || "";

				// Allow writing design docs
				if (path.includes("docs/") || path.includes("designs/") || path.includes("plans/")) {
					return;
				}

				updateStatus(ctx);
				return {
					block: true,
					reason: [
						"🔒 WORKFLOW GATE: Cannot write/edit code during brainstorming phase.",
						"The design must be discussed and approved first.",
						"Write design docs to docs/designs/ if needed.",
						"Use /advance to move to the planning phase when the design is approved.",
					].join("\n"),
				};
			}
		}

		if (state.phase === "plan") {
			if (isToolCallEventType("write", event) || isToolCallEventType("edit", event)) {
				const path = (event.input as any)?.path || "";

				// Allow writing plan docs
				if (path.includes("docs/") || path.includes("plans/") || path.includes("designs/")) {
					return;
				}

				updateStatus(ctx);
				return {
					block: true,
					reason: [
						"🔒 WORKFLOW GATE: Cannot write/edit code during planning phase.",
						"Complete the plan first. Write plan docs to docs/plans/.",
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
				ctx.ui.notify("No active workflow. Start by describing a task.", "warning");
				return;
			}

			if (currentIndex >= PHASE_ORDER.length - 1) {
				setPhase("idle");
				updateStatus(ctx);
				ctx.ui.notify("Workflow complete! Ready for new tasks.", "success");
				return;
			}

			const nextPhase = PHASE_ORDER[currentIndex + 1];
			setPhase(nextPhase);
			updateStatus(ctx);
			ctx.ui.notify(`Advanced to: ${PHASE_ICONS[nextPhase]} ${nextPhase}`, "info");
		},
	});

	// /phase - set phase directly
	pi.registerCommand("phase", {
		description: "Set workflow phase (brainstorm, plan, implement, review, verify, complete, idle)",
		handler: async (args, ctx) => {
			const phase = args.trim().toLowerCase() as WorkflowPhase;
			const validPhases: WorkflowPhase[] = ["idle", "brainstorm", "plan", "implement", "review", "verify", "complete"];

			if (!validPhases.includes(phase)) {
				ctx.ui.notify(`Invalid phase. Valid: ${validPhases.join(", ")}`, "error");
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
