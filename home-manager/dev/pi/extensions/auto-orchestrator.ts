/**
 * Autonomous Orchestrator Extension
 *
 * Provides /auto command that drives the full workflow autonomously:
 *   brainstorm → plan → implement → review → verify
 *
 * Switches to the strongest model (Opus) at max thinking for orchestration,
 * then uses subagents for each phase. Escalates to the user after 3 failures
 * in any phase. Restores original model/thinking when complete.
 */

import type {
	ExtensionAPI,
	ExtensionContext,
} from "@mariozechner/pi-coding-agent";

const ORCHESTRATOR_MODEL_PROVIDER = "github-copilot";
const ORCHESTRATOR_MODEL_ID = "claude-opus-4-7";
const ORCHESTRATOR_THINKING_LEVEL = "xhigh" as const;

const ORCHESTRATION_PROMPT = `You are now operating as an AUTONOMOUS ORCHESTRATOR. Your job is to drive the full development workflow to completion without human intervention.

## Your Role

You are the orchestrator. You do NOT implement anything yourself. You delegate ALL work to specialized subagents, evaluate their output, and decide what happens next. You use the strongest model at maximum thinking effort because your job is to make the right decisions — the subagents do the grunt work.

## Workflow Phases

Execute these phases in order. Do NOT skip phases.

### Phase 1: Brainstorm
- Dispatch the "brainstormer" agent with the task description
- Evaluate the brainstormer's output: Are there clear approaches with tradeoffs? Is one recommended?
- If the output is weak or incomplete, re-dispatch with more specific guidance (up to 3 attempts)
- Select the best approach from the brainstormer's output. State which approach you're choosing and why.

### Phase 2: Scout & Plan
- Dispatch the "scout" agent to gather codebase context relevant to the chosen approach
- Then dispatch the "planner" agent with the scout's findings and the chosen approach
- Evaluate the plan: Are steps small, specific, and verifiable? Are file paths exact? Are verification commands concrete?
- If the plan is weak, re-dispatch the planner with specific feedback (up to 3 attempts)
- Once satisfied, use the plan tool to create the plan formally

### Phase 3: Implement
- Execute the plan step by step using the "worker" agent
- For each step:
  1. Curate exactly the context the worker needs (step description, relevant files, previous step output if needed)
  2. Dispatch the worker with that curated context
  3. Read the worker's verification output — do NOT trust "DONE" status alone
  4. Update the plan step status (done/failed)
  5. If a step fails, retry with adjusted instructions (up to 3 attempts per step)
- Identify steps that can run in parallel (no shared files, no dependencies) and dispatch them together
- Keep going without pausing — move to the next step immediately after a success

### Phase 4: Review
- Run a two-stage review:
  1. Dispatch "spec-reviewer" to check spec compliance — did we build what was asked?
  2. Dispatch "reviewer" to check code quality — is it well-built?
- Evaluate review results:
  - If PASS: proceed to verification
  - If PASS_WITH_ISSUES (no Critical issues): dispatch "worker" to fix Important issues, then re-review
  - If FAIL (Critical issues): dispatch "worker" to fix Critical issues, then re-review from scratch
- Maximum 3 review-fix cycles before escalating

### Phase 5: Verify
- Run verification commands from the plan (tests, builds, type checks)
- Use bash to execute verification commands directly
- If verification fails, dispatch "worker" to fix, then re-verify (up to 3 attempts)

## Failure Escalation

If any phase fails 3 times, STOP and report to the user:
- Which phase failed
- What was attempted
- What the errors/issues were
- Your assessment of what's wrong
- Suggested next steps

Do NOT keep retrying past 3 failures. The human needs to intervene.

## Subagent Usage Patterns

For sequential work (most phases):
\`\`\`
Use the subagent tool in single mode:
  agent: "scout"
  task: "Find all code relevant to..."
\`\`\`

For independent plan steps:
\`\`\`
Use the subagent tool in parallel mode:
  tasks: [
    { agent: "worker", task: "Step 3: ..." },
    { agent: "worker", task: "Step 4: ..." }
  ]
\`\`\`

For scout→planner handoff:
\`\`\`
Use the subagent tool in chain mode:
  chain: [
    { agent: "scout", task: "Find code relevant to..." },
    { agent: "planner", task: "Create plan for... using context: {previous}" }
  ]
\`\`\`

## Rules

1. NEVER implement code yourself — always delegate to subagents
2. NEVER skip a phase — the workflow exists for a reason
3. ALWAYS read subagent output critically — workers report optimistically
4. ALWAYS update plan status after each step
5. Keep your orchestration messages concise — save context for decision-making
6. After all phases complete successfully, provide a final summary:
   - What was built
   - Key design decisions
   - Files changed
   - Verification results
7. When the workflow is fully complete (all phases passed), call /auto-done to restore the original model and thinking level
8. If you escalate to the user due to 3 failures, also call /auto-done so they get their normal model back

## Interaction with Workflow Gate

The workflow gate extension may be active. Ignore its phase tracking — you manage your own phases via subagents. The gate will not block subagent work since subagents run in separate processes. If you need to write files directly (e.g., for verification), you can do so freely.

## Begin

Start Phase 1 (Brainstorm) now. The task is described below.`;

export default function (pi: ExtensionAPI) {
	let originalModel: any;
	let originalThinkingLevel:
		| "off"
		| "minimal"
		| "low"
		| "medium"
		| "high"
		| "xhigh" = "medium";
	let isOrchestrating = false;

	// Inject orchestration system prompt when active
	pi.on("before_agent_start", async (event) => {
		if (!isOrchestrating) return;

		return {
			systemPrompt: event.systemPrompt + "\n\n" + ORCHESTRATION_PROMPT,
		};
	});

	// Detect when orchestration completes and restore state
	pi.on("agent_end", async (_event, ctx) => {
		if (!isOrchestrating) return;

		// Check if the agent's response indicates completion or escalation
		// We restore model/thinking here so the user is back to normal
		// The orchestrator will have finished its work by agent_end
	});

	pi.registerCommand("auto", {
		description:
			"Autonomous workflow — brainstorm → plan → implement → review → verify",
		handler: async (args, ctx) => {
			const task = args?.trim();
			if (!task) {
				ctx.ui.notify("Usage: /auto <task description>", "warning");
				return;
			}

			// Save current state for restoration
			originalModel = ctx.model;
			originalThinkingLevel = pi.getThinkingLevel();

			// Switch to orchestrator model
			const orchestratorModel = ctx.modelRegistry.find(
				ORCHESTRATOR_MODEL_PROVIDER,
				ORCHESTRATOR_MODEL_ID,
			);

			if (!orchestratorModel) {
				ctx.ui.notify(
					`Orchestrator model ${ORCHESTRATOR_MODEL_PROVIDER}/${ORCHESTRATOR_MODEL_ID} not found. Check model availability.`,
					"error",
				);
				return;
			}

			const modelSet = await pi.setModel(orchestratorModel);
			if (!modelSet) {
				ctx.ui.notify(
					`No API key available for ${ORCHESTRATOR_MODEL_PROVIDER}/${ORCHESTRATOR_MODEL_ID}`,
					"error",
				);
				return;
			}

			// Set max thinking
			pi.setThinkingLevel(ORCHESTRATOR_THINKING_LEVEL);

			// Mark orchestration as active
			isOrchestrating = true;

			// Update UI
			ctx.ui.setWidget(
				"orchestrator",
				[
					"🤖 AUTONOMOUS MODE — Opus orchestrating",
					`Task: ${task.length > 60 ? task.slice(0, 57) + "..." : task}`,
				],
				{ placement: "belowEditor" },
			);

			ctx.ui.notify("🤖 Autonomous orchestration started", "info");

			// Set workflow gate phase to implement to avoid it blocking any direct writes
			// The orchestrator delegates via subagents anyway, but just in case
			pi.events.emit("auto:orchestration-started");

			// Send the task as a user message — this triggers the agent loop
			// The ORCHESTRATION_PROMPT is injected via before_agent_start
			pi.sendUserMessage(
				`Autonomous orchestration task:\n\n${task}\n\nBegin the autonomous workflow now. Start with Phase 1 (Brainstorm).`,
			);
		},
	});

	// Command to stop orchestration and restore state
	pi.registerCommand("auto-stop", {
		description:
			"Stop autonomous orchestration and restore original model/thinking",
		handler: async (_args, ctx) => {
			if (!isOrchestrating) {
				ctx.ui.notify("No active orchestration to stop.", "info");
				return;
			}

			isOrchestrating = false;

			// Restore original model
			if (originalModel) {
				await pi.setModel(originalModel);
			}

			// Restore original thinking level
			pi.setThinkingLevel(originalThinkingLevel);

			// Clear UI
			ctx.ui.setWidget("orchestrator", []);

			ctx.ui.notify(
				"🛑 Autonomous orchestration stopped. Model and thinking level restored.",
				"info",
			);
		},
	});

	// Provide /auto-done for the orchestrator to call when finished
	pi.registerCommand("auto-done", {
		description:
			"Signal that autonomous orchestration is complete (restores model/thinking)",
		handler: async (_args, ctx) => {
			if (!isOrchestrating) return;

			isOrchestrating = false;

			// Restore original model
			if (originalModel) {
				await pi.setModel(originalModel);
			}

			// Restore original thinking level
			pi.setThinkingLevel(originalThinkingLevel);

			// Clear UI
			ctx.ui.setWidget("orchestrator", []);

			ctx.ui.notify(
				"✅ Autonomous orchestration complete. Model and thinking level restored.",
				"success",
			);
		},
	});

	// Track session start to reset state
	pi.on("session_start", async (_event, _ctx) => {
		isOrchestrating = false;
		originalModel = undefined;
		originalThinkingLevel = "medium";
	});
}
