/**
 * Two-Stage Review Extension
 *
 * Provides a /review command and review tool that orchestrates:
 * Stage 1: Spec compliance review (did they build what was asked?)
 * Stage 2: Code quality review (is it well-built?) — only if Stage 1 passes
 *
 * Uses subagent chain for the review pipeline.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, _ctx) => {
		// Restore any review state if needed
	});

	// Detect merge/push attempts and warn if no review was done
	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return;

		const command = (event.input as any)?.command || "";
		const isMerge = /\bgit\s+merge\b/i.test(command);
		const isPush = /\bgit\s+push\b/i.test(command);

		if (!isMerge && !isPush) return;

		// Check if a review was done this session
		let reviewDone = false;
		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type === "custom" && entry.customType === "superpowers:review") {
				reviewDone = true;
			}
		}

		if (!reviewDone) {
			const ok = await ctx.ui.confirm(
				"No review on record",
				`You're about to ${isMerge ? "merge" : "push"} without a recorded review.\n\nContinue anyway?`,
			);
			if (!ok) {
				return { block: true, reason: "Blocked: no review done. Run /review first." };
			}
		}
	});

	// /review command — triggers two-stage review via subagents
	pi.registerCommand("review", {
		description: "Run two-stage review: spec compliance, then code quality",
		handler: async (args, ctx) => {
			const target = args.trim() || "the recent changes in this session";

			// Record that a review was initiated
			pi.appendEntry("superpowers:review", {
				type: "initiated",
				target,
				timestamp: Date.now(),
			});

			ctx.ui.notify("Starting two-stage review...", "info");

			// Send a user message that triggers the subagent chain
			pi.sendUserMessage(
				[
					`Run a two-stage code review using the subagent tool with a chain:`,
					``,
					`Stage 1 - Use the "spec-reviewer" agent:`,
					`Review ${target} for spec compliance. Check:`,
					`- Were all requirements met?`,
					`- Is anything missing?`,
					`- Is anything extra/unneeded?`,
					`- Do NOT trust any self-reported status — read the actual code.`,
					``,
					`Stage 2 - Use the "reviewer" agent (pass {previous} from Stage 1):`,
					`Only if Stage 1 passed, review for code quality:`,
					`- Architecture and design`,
					`- Error handling and edge cases`,
					`- DRY violations`,
					`- Test coverage`,
					`Categorize issues as: Critical / Important / Minor`,
					``,
					`Report both stages' findings.`,
				].join("\n"),
				{ deliverAs: "followUp" },
			);
		},
	});
}
