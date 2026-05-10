/**
 * Session Dashboard Extension
 *
 * Persistent widget showing workflow phase, verification status,
 * plan progress, debug attempts, and session stats.
 * Reads state from other superpowers extensions via session entries.
 */

import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";

interface DashboardState {
	workflowPhase: string;
	testsRun: boolean;
	testsPassed: number;
	testsFailed: number;
	buildPassed: boolean | null;
	planTotal: number;
	planComplete: number;
	planName: string;
	debugAttempts: number;
	debugMaxForIssue: number;
	filesChanged: Set<string>;
	totalCost: number;
	totalTurns: number;
	sessionStartTime: number;
}

const PHASE_ICONS: Record<string, string> = {
	idle: "💤",
	brainstorm: "💡",
	plan: "📋",
	implement: "🔨",
	review: "🔍",
	verify: "✅",
	complete: "🎉",
};

export default function (pi: ExtensionAPI) {
	const state: DashboardState = {
		workflowPhase: "idle",
		testsRun: false,
		testsPassed: 0,
		testsFailed: 0,
		buildPassed: null,
		planTotal: 0,
		planComplete: 0,
		planName: "",
		debugAttempts: 0,
		debugMaxForIssue: 0,
		filesChanged: new Set(),
		totalCost: 0,
		totalTurns: 0,
		sessionStartTime: Date.now(),
	};

	function refreshFromEntries(entries: any[]) {
		for (const entry of entries) {
			if (entry.type !== "custom") continue;

			switch (entry.customType) {
				case "superpowers:workflow": {
					const data = entry.data as { phase?: string };
					if (data?.phase) state.workflowPhase = data.phase;
					break;
				}
				case "superpowers:verification": {
					const data = entry.data as any;
					if (data) {
						state.testsRun = data.testsRun ?? false;
						state.testsPassed = data.testsPassed ?? 0;
						state.testsFailed = data.testsFailed ?? 0;
						state.buildPassed = data.buildRun ? data.buildPassed : null;
					}
					break;
				}
				case "superpowers:plan": {
					const data = entry.data as any;
					if (data?.steps) {
						state.planTotal = data.steps.length;
						state.planComplete = data.steps.filter(
							(s: any) => s.status === "done",
						).length;
						state.planName = data.name || "";
					}
					break;
				}
				case "superpowers:debug": {
					const data = entry.data as any;
					if (data) {
						state.debugAttempts = data.totalAttempts ?? 0;
						state.debugMaxForIssue = data.maxAttemptsForIssue ?? 0;
					}
					break;
				}
			}
		}
	}

	function renderWidget(ctx: ExtensionContext) {
		const lines: string[] = [];
		const parts: string[] = [];

		// Verification
		if (state.testsRun) {
			if (state.testsFailed > 0) {
				parts.push(`🔴 ${state.testsPassed}✓ ${state.testsFailed}✗`);
			} else {
				parts.push(`✅ ${state.testsPassed}✓`);
			}
		}

		if (state.buildPassed !== null) {
			parts.push(state.buildPassed ? "🏗✓" : "🏗✗");
		}

		// Plan progress
		if (state.planTotal > 0) {
			const pct = Math.round((state.planComplete / state.planTotal) * 100);
			parts.push(`📋 ${state.planComplete}/${state.planTotal} (${pct}%)`);
		}

		// Debug attempts
		if (state.debugAttempts > 0) {
			const warn = state.debugMaxForIssue >= 3 ? "⚠" : "";
			parts.push(`🐛 ${state.debugAttempts} fixes${warn}`);
		}

		// Session time
		const elapsed = Math.round((Date.now() - state.sessionStartTime) / 60000);
		if (elapsed > 0) {
			parts.push(`⏱ ${elapsed}m`);
		}

		// Files changed
		if (state.filesChanged.size > 0) {
			parts.push(`📝 ${state.filesChanged.size} files`);
		}

		lines.push(parts.join(" │ "));
		ctx.ui.setWidget("dashboard", lines, { placement: "belowEditor" });
	}

	pi.on("session_start", async (_event, ctx) => {
		state.sessionStartTime = Date.now();
		state.filesChanged = new Set();
		state.totalCost = 0;
		state.totalTurns = 0;

		refreshFromEntries(ctx.sessionManager.getEntries());
		renderWidget(ctx);
	});

	// Track file changes
	pi.on("tool_call", async (event, _ctx) => {
		if (event.toolName === "write" || event.toolName === "edit") {
			const path = (event.input as any)?.path;
			if (path) state.filesChanged.add(path);
		}
	});

	// Track costs and turns
	pi.on("message_end", async (event, ctx) => {
		if (event.message.role === "assistant") {
			state.totalTurns++;
			const cost = event.message.usage?.cost?.total;
			if (cost) state.totalCost += cost;
		}

		// Re-read entries to pick up changes from other extensions
		refreshFromEntries(ctx.sessionManager.getEntries());
		renderWidget(ctx);
	});

	pi.on("turn_end", async (_event, ctx) => {
		refreshFromEntries(ctx.sessionManager.getEntries());
		renderWidget(ctx);
	});

	pi.registerCommand("dashboard", {
		description: "Show full session dashboard",
		handler: async (_args, ctx) => {
			const lines: string[] = ["═══ Session Dashboard ═══"];
			lines.push(
				`Phase: ${PHASE_ICONS[state.workflowPhase] || "❓"} ${state.workflowPhase}`,
			);
			lines.push("");

			lines.push("── Verification ──");
			lines.push(
				`  Tests: ${state.testsRun ? `${state.testsPassed} passed, ${state.testsFailed} failed` : "not run"}`,
			);
			lines.push(
				`  Build: ${state.buildPassed === null ? "not run" : state.buildPassed ? "passed" : "failed"}`,
			);
			lines.push("");

			if (state.planTotal > 0) {
				lines.push("── Plan ──");
				lines.push(
					`  ${state.planName || "Active plan"}: ${state.planComplete}/${state.planTotal} steps`,
				);
				lines.push("");
			}

			if (state.debugAttempts > 0) {
				lines.push("── Debugging ──");
				lines.push(`  Total fix attempts: ${state.debugAttempts}`);
				lines.push(`  Max per issue: ${state.debugMaxForIssue}`);
				lines.push("");
			}

			lines.push("── Session ──");
			const elapsed = Math.round((Date.now() - state.sessionStartTime) / 60000);
			lines.push(`  Duration: ${elapsed} minutes`);
			lines.push(`  Turns: ${state.totalTurns}`);
			lines.push(`  Files changed: ${state.filesChanged.size}`);
			if (state.totalCost > 0)
				lines.push(`  Cost: $${state.totalCost.toFixed(4)}`);

			if (state.filesChanged.size > 0) {
				lines.push("");
				lines.push("── Files Changed ──");
				for (const f of state.filesChanged) {
					lines.push(`  ${f}`);
				}
			}

			ctx.ui.notify(lines.join("\n"), "info");
		},
	});
}
