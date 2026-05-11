/**
 * Workflow Gate Extension
 *
 * Enforces the brainstorm → plan → implement → review → verify workflow.
 * Uses a cheap LLM call to classify task intent (feature/bug/small/question).
 * Tracks current phase and blocks premature tool calls.
 *
 * Phase transition model:
 *   brainstorm → plan:      Manual (/advance) — requires human approval
 *   plan → implement:       Manual (/advance) — requires human approval
 *   implement → review:     Auto — when spec-reviewer/reviewer subagent dispatched
 *   review → implement:     Auto — when worker subagent dispatched (fix cycle)
 *   review → verify:        Auto — when bash test/build command succeeds
 *   verify → implement:     Auto — when bash test/build command fails
 *   verify → complete:      Auto — when bash test/build passes cleanly
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  isToolCallEventType,
  isBashToolResult,
} from "@earendil-works/pi-coding-agent";
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
  /** Track whether we've seen a passing verification in the verify phase */
  verificationPassed: boolean;
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

/** Phases that require manual /advance (human approval gates) */
const MANUAL_GATE_PHASES: WorkflowPhase[] = ["brainstorm", "plan"];

/** Phases that auto-transition based on agent behavior */
const AUTO_FLOW_PHASES: WorkflowPhase[] = ["implement", "review", "verify"];

const PHASE_ORDER: WorkflowPhase[] = [
  "brainstorm",
  "plan",
  "implement",
  "review",
  "verify",
  "complete",
];

/** Patterns that indicate a test/build command in bash */
const TEST_BUILD_PATTERNS = [
  /\bnpm\s+test\b/,
  /\bnpx\s+(vitest|jest|mocha)\b/,
  /\bcargo\s+test\b/,
  /\bpytest\b/,
  /\bgo\s+test\b/,
  /\bmake\s+test\b/,
  /\bnpm\s+run\s+(test|build|check|lint)\b/,
  /\bnpx\s+tsc\b/,
  /\bcargo\s+(build|check|clippy)\b/,
  /\bgo\s+(build|vet)\b/,
  /\bmake\s+build\b/,
  /\bnix\s+build\b/,
  /\bnix-build\b/,
  /\bnix-instantiate\s+--parse\b/,
];

/** Patterns in bash output that indicate test failures */
const TEST_FAILURE_PATTERNS = [
  /FAIL(?:ED|URE)?[\s:]/i,
  /(\d+)\s+(?:tests?\s+)?fail/i,
  /error(?:\[|\s*:|\s+TS)/i,
  /Error:/,
  /FAILED/,
  /panic:/,
  /assertion failed/i,
];

/** Review agent names that trigger implement→review transition */
const REVIEW_AGENTS = ["spec-reviewer", "reviewer"];

/** Implementation agent names that trigger review→implement transition (fix cycle) */
const WORKER_AGENTS = ["worker"];

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
  const candidates = [
    ctx.modelRegistry.find("github-copilot", "claude-haiku-4.5"),
    ctx.modelRegistry.find("github-copilot", "gpt-4o-mini"),
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

/** Check if a bash command looks like a test or build command */
function isTestOrBuildCommand(command: string): boolean {
  return TEST_BUILD_PATTERNS.some((pattern) => pattern.test(command));
}

/** Check if bash output contains test failure indicators */
function hasTestFailures(output: string): boolean {
  return TEST_FAILURE_PATTERNS.some((pattern) => pattern.test(output));
}

/** Get all agent names from a subagent tool call (for multi-agent dispatches) */
function getAllSubagentNames(input: Record<string, unknown>): string[] {
  const names: string[] = [];

  if (typeof input.agent === "string") names.push(input.agent);

  if (Array.isArray(input.chain)) {
    for (const step of input.chain) {
      if (typeof step?.agent === "string") names.push(step.agent);
    }
  }

  if (Array.isArray(input.tasks)) {
    for (const task of input.tasks) {
      if (typeof task?.agent === "string") names.push(task.agent);
    }
  }

  return names;
}

export default function(pi: ExtensionAPI) {
  let state: WorkflowState = {
    phase: "idle",
    taskDescription: "",
    phaseHistory: [],
    gateEnabled: true,
    verificationPassed: false,
  };

  let pendingClassification: Promise<TaskType> | null = null;

  /** When true, the auto-orchestrator is active and manages its own phases.
   *  The workflow gate suppresses auto-transitions and steering messages,
   *  but keeps the phase widget updated for visibility. */
  let autoOrchestratorActive = false;

  // Listen for auto-orchestrator lifecycle events
  pi.events.on("auto:orchestration-started", () => {
    autoOrchestratorActive = true;
  });
  pi.events.on("auto:orchestration-stopped", () => {
    autoOrchestratorActive = false;
  });

  function setPhase(phase: WorkflowPhase, reason?: string) {
    const prev = state.phase;
    state.phase = phase;
    state.phaseHistory.push({ phase, timestamp: Date.now() });

    // Reset verification tracking when entering verify phase
    if (phase === "verify") {
      state.verificationPassed = false;
    }

    pi.appendEntry("superpowers:workflow", {
      phase,
      previousPhase: prev,
      reason,
      taskDescription: state.taskDescription,
    });
  }

  function updateStatus(ctx: {
    ui: { setWidget: (id: string, lines: string[], options?: any) => void };
  }) {
    const icon = PHASE_ICONS[state.phase];
    const isManualGate = MANUAL_GATE_PHASES.includes(state.phase);
    const isAutoFlow = AUTO_FLOW_PHASES.includes(state.phase);
    const gateIndicator = !state.gateEnabled
      ? "🔓"
      : isManualGate
        ? "🔒"
        : isAutoFlow
          ? "🔄"
          : "";
    ctx.ui.setWidget("workflow", [`${icon} ${state.phase} ${gateIndicator}`], {
      placement: "belowEditor",
    });
  }

  /** Auto-transition: send a steering message to guide the agent */
  function steerForPhase(phase: WorkflowPhase, reason: string) {
    const steerMessages: Record<string, string> = {
      review: [
        `🔄 AUTO-TRANSITION: Moving to review phase (${reason}).`,
        "Run a two-stage review: first spec compliance, then code quality.",
        "Use /review or dispatch spec-reviewer and reviewer subagents.",
      ].join("\n"),
      implement: [
        `🔄 AUTO-TRANSITION: Moving back to implementation (${reason}).`,
        "Fix the issues identified, then re-run review/verification.",
      ].join("\n"),
      verify: [
        `🔄 AUTO-TRANSITION: Moving to verification phase (${reason}).`,
        "Run the full test suite and build. Show the output.",
        "Demonstrate the change works with concrete evidence.",
      ].join("\n"),
      complete: [
        "🎉 AUTO-TRANSITION: Verification passed. The work is complete.",
        "Summarise what was done, files changed, and verification results.",
      ].join("\n"),
    };

    const message = steerMessages[phase];
    if (message) {
      pi.sendMessage(
        {
          customType: "superpowers:workflow-hint",
          content: message,
          display: true,
        },
        { deliverAs: "steer" },
      );
    }
  }

  function applyClassification(
    taskType: TaskType,
    ctx: {
      ui: { setWidget: (id: string, lines: string[], options?: any) => void };
    },
  ) {
    if (taskType === "feature") {
      setPhase("brainstorm", "classified as feature");
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
      setPhase("implement", "classified as bug fix");
      updateStatus(ctx);
      pi.sendMessage(
        {
          customType: "superpowers:workflow-hint",
          content: [
            "🔧 WORKFLOW: Bug fix detected.",
            "Investigate the root cause first — don't guess at fixes.",
            "Load the systematic-debugging skill.",
            "After fixing, the workflow will auto-advance through review → verify.",
          ].join("\n"),
          display: true,
        },
        { deliverAs: "steer" },
      );
    } else if (taskType === "small") {
      setPhase("implement", "classified as small change");
      updateStatus(ctx);
    } else {
      updateStatus(ctx);
    }
  }

  // ── Session lifecycle ──────────────────────────────────────────────

  pi.on("session_start", async (_event, ctx) => {
    state = {
      phase: "idle",
      taskDescription: "",
      phaseHistory: [],
      gateEnabled: true,
      verificationPassed: false,
    };
    pendingClassification = null;

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

  // ── Classification ─────────────────────────────────────────────────

  pi.on("before_agent_start", async (event, ctx) => {
    const prompt = event.prompt;
    if (!prompt) return;

    if (state.phase !== "idle" && state.phase !== "complete") return;

    state.taskDescription = prompt;

    const conversationContext = buildConversationContext(ctx.sessionManager);

    ctx.ui.setWidget("workflow", ["🔍 Classifying task..."], {
      placement: "belowEditor",
    });

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
  });

  // ── Tool call gating + auto-transition detection ───────────────────

  pi.on("tool_call", async (event, ctx) => {
    if (!state.gateEnabled) return;

    const isGatedTool =
      isToolCallEventType("write", event) ||
      isToolCallEventType("edit", event) ||
      isToolCallEventType("subagent", event);

    if (pendingClassification && isGatedTool) {
      await pendingClassification;
    }

    // ── Auto-transitions on subagent dispatch ──
    // (Suppressed when auto-orchestrator is active — it manages its own phases)

    if (isToolCallEventType("subagent", event) && !autoOrchestratorActive) {
      const agents = getAllSubagentNames(event.input);

      // implement → review: dispatching a reviewer agent
      if (state.phase === "implement") {
        const dispatchingReviewer = agents.some((a) =>
          REVIEW_AGENTS.includes(a),
        );
        if (dispatchingReviewer) {
          setPhase("review", `dispatched ${agents.join(", ")}`);
          updateStatus(ctx);
          // Don't steer here — the agent already knows what it's doing
        }
      }

      // review → implement: dispatching a worker agent (fix cycle)
      if (state.phase === "review") {
        const dispatchingWorker = agents.some((a) => WORKER_AGENTS.includes(a));
        if (dispatchingWorker) {
          setPhase("implement", `fix cycle — dispatched ${agents.join(", ")}`);
          updateStatus(ctx);
          // Don't steer — the agent is already fixing issues
        }
      }
    }

    // ── Brainstorm/plan gates (manual only) ──

    if (state.phase === "brainstorm") {
      if (
        isToolCallEventType("write", event) ||
        isToolCallEventType("edit", event)
      ) {
        const path = (event.input as any)?.path || "";

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

  // ── Tool result detection for verify auto-transitions ──────────────

  pi.on("tool_result", async (event, ctx) => {
    if (!state.gateEnabled) return;
    // Suppress auto-transitions when auto-orchestrator manages its own phases
    if (autoOrchestratorActive) return;

    // Only care about bash results for test/build detection
    if (!isBashToolResult(event)) return;

    const command = (event.input as any)?.command || "";
    if (!isTestOrBuildCommand(command)) return;

    const output = event.content
      .filter((c): c is { type: "text"; text: string } => c.type === "text")
      .map((c) => c.text)
      .join("\n");

    const failed = event.isError || hasTestFailures(output);

    // review phase + test/build run → transition to verify or stay in review
    if (state.phase === "review") {
      if (!failed) {
        setPhase("verify", "test/build passed during review");
        updateStatus(ctx);
        // Don't steer — let the agent continue naturally
      }
      // If tests fail during review, stay in review — the agent needs to
      // dispatch a worker to fix before re-running
    }

    // verify phase — assess whether verification passed or failed
    if (state.phase === "verify") {
      if (failed) {
        setPhase("implement", "verification failed — tests/build broken");
        updateStatus(ctx);
        steerForPhase(
          "implement",
          "verification failed — fix the issues and re-verify",
        );
      } else {
        state.verificationPassed = true;
        setPhase("complete", "verification passed");
        updateStatus(ctx);
        steerForPhase("complete", "all checks passed");
      }
    }

    // implement phase + test/build passed → transition to verify
    // (handles cases where agent runs tests directly without explicit review dispatch)
    if (state.phase === "implement") {
      if (!failed) {
        // Only auto-advance to verify if we've been through review at least once,
        // or if this is a small/bug workflow that skips formal review
        const hasHadReview = state.phaseHistory.some(
          (h) => h.phase === "review",
        );
        const isSmallOrBug =
          state.phaseHistory.length > 0 &&
          !state.phaseHistory.some((h) => h.phase === "brainstorm");

        if (hasHadReview || isSmallOrBug) {
          setPhase("verify", "test/build passed");
          updateStatus(ctx);
        }
      }
    }
  });

  // ── /advance - manual phase advancement ────────────────────────────

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
        setPhase("idle", "workflow complete via /advance");
        updateStatus(ctx);
        ctx.ui.notify("Workflow complete! Ready for new tasks.", "info");
        return;
      }

      const nextPhase = PHASE_ORDER[currentIndex + 1];
      setPhase(nextPhase, "manual /advance");
      updateStatus(ctx);

      const autoFlowNote = AUTO_FLOW_PHASES.includes(nextPhase)
        ? " (auto-transitions active from here)"
        : "";
      ctx.ui.notify(
        `Advanced to: ${PHASE_ICONS[nextPhase]} ${nextPhase}${autoFlowNote}`,
        "info",
      );

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
          "The workflow will auto-advance to review when you dispatch a reviewer,",
          "and auto-advance to verify when tests pass.",
          "Load the executing-plans skill for guidance.",
        ].join(" "),
        review: [
          "Implementation is complete. Move to review.",
          "Run a two-stage review: first spec compliance (did we build what was asked?),",
          "then code quality (is it well-built?).",
          "Use /review or dispatch spec-reviewer and reviewer subagents.",
          "The workflow will auto-regress to implement if fixes are needed,",
          "and auto-advance to verify when tests pass.",
        ].join(" "),
        verify: [
          "Review is complete. Move to verification.",
          "Run the full test suite and build. Show the output.",
          "Demonstrate the change works with concrete evidence.",
          "No hedging — show actual results.",
          "The workflow will auto-complete on success, or regress to implement on failure.",
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

  // ── /phase - set phase directly ────────────────────────────────────

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

      setPhase(phase, "manual /phase");
      updateStatus(ctx);
      ctx.ui.notify(`Phase set to: ${PHASE_ICONS[phase]} ${phase}`, "info");
    },
  });

  // ── /gate - toggle gate enforcement ────────────────────────────────

  pi.registerCommand("gate", {
    description: "Toggle workflow gate enforcement on/off",
    handler: async (_args, ctx) => {
      state.gateEnabled = !state.gateEnabled;
      updateStatus(ctx);
      ctx.ui.notify(
        state.gateEnabled
          ? "🔒 Workflow gate ENABLED — brainstorm/plan gates + auto-transitions active"
          : "🔓 Workflow gate DISABLED — all tool calls allowed, no auto-transitions",
        "info",
      );
    },
  });
}
