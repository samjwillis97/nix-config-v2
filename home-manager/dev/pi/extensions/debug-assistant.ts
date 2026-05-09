/**
 * Debug Assistant Extension
 *
 * Tracks fix attempts per error signature. After repeated failures,
 * warns the agent to step back and rethink. Detects debugging sessions
 * and provides structured tracking.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isBashToolResult } from "@mariozechner/pi-coding-agent";

interface DebugIssue {
	signature: string;
	firstSeen: number;
	attempts: number;
	commands: string[];
	escalated: boolean;
}

interface DebugState {
	issues: Map<string, DebugIssue>;
	totalAttempts: number;
	isDebugging: boolean;
}

// Patterns that indicate an error in bash output
const ERROR_PATTERNS = [
	/error(?:\[|\s*:|\s+TS)/i,
	/Error:/,
	/FAIL(?:ED|URE)?[\s:]/,
	/(?:Traceback|Exception|panic|PANIC)/,
	/(?:cannot|can't|couldn't)\s+(?:find|resolve|read|open|import)/i,
	/(?:undefined|null)\s+(?:is not|reference)/i,
	/(?:syntax|type|reference|range)\s*error/i,
	/compilation?\s+(?:error|failed)/i,
	/build\s+failed/i,
	/test.*failed/i,
	/exit\s+(?:code|status)\s+[1-9]/i,
	/segmentation\s+fault/i,
	/stack\s+overflow/i,
	/out\s+of\s+memory/i,
];

// Create a rough "signature" for an error to group related attempts
function extractErrorSignature(output: string): string | null {
	for (const pattern of ERROR_PATTERNS) {
		const match = output.match(pattern);
		if (match) {
			// Get a few lines around the match for context
			const lines = output.split("\n");
			const matchIndex = lines.findIndex((l) => pattern.test(l));
			if (matchIndex >= 0) {
				// Use the error line + file/line reference if present
				const errorLine = lines[matchIndex].trim().slice(0, 120);
				// Look for file:line patterns nearby
				const nearby = lines.slice(Math.max(0, matchIndex - 2), matchIndex + 3).join("\n");
				const fileRef = nearby.match(/[\w./\\-]+\.\w+[:\s]+\d+/)?.[0] || "";
				return `${errorLine}${fileRef ? ` @ ${fileRef}` : ""}`;
			}
			return match[0].slice(0, 120);
		}
	}
	return null;
}

// Detect if a command looks like a fix attempt (vs just investigation)
function isFixAttempt(command: string): boolean {
	// Commands that modify code are fix attempts
	return false; // We track this via write/edit tool calls instead
}

export default function (pi: ExtensionAPI) {
	let state: DebugState = {
		issues: new Map(),
		totalAttempts: 0,
		isDebugging: false,
	};

	let lastError: string | null = null;
	let writesSinceLastError = 0;

	function persistState() {
		const maxForIssue = Math.max(0, ...Array.from(state.issues.values()).map((i) => i.attempts));
		pi.appendEntry("superpowers:debug", {
			totalAttempts: state.totalAttempts,
			maxAttemptsForIssue: maxForIssue,
			issueCount: state.issues.size,
			isDebugging: state.isDebugging,
		});
	}

	pi.on("session_start", async () => {
		state = { issues: new Map(), totalAttempts: 0, isDebugging: false };
		lastError = null;
		writesSinceLastError = 0;
	});

	// Track errors from bash output
	pi.on("tool_result", async (event, ctx) => {
		if (!isBashToolResult(event)) return;

		const output = event.content
			.filter((c): c is { type: "text"; text: string } => c.type === "text")
			.map((c) => c.text)
			.join("\n");

		const signature = extractErrorSignature(output);

		if (signature) {
			state.isDebugging = true;
			lastError = signature;
			writesSinceLastError = 0;

			let issue = state.issues.get(signature);
			if (!issue) {
				issue = {
					signature,
					firstSeen: Date.now(),
					attempts: 0,
					commands: [],
					escalated: false,
				};
				state.issues.set(signature, issue);
			}

			// Record the command
			const command = (event.input as any)?.command || "";
			if (command && !issue.commands.includes(command)) {
				issue.commands.push(command.slice(0, 200));
			}

			persistState();
			ctx.ui.setWidget("debug", [`🐛 Debugging: ${signature.slice(0, 50)}...`], { placement: "belowEditor" });
		} else if (state.isDebugging && !event.isError) {
			// Error seems resolved — check if last error is gone
			const command = (event.input as any)?.command || "";
			const isTestOrBuild =
				/\b(test|build|check|compile)\b/i.test(command);

			if (isTestOrBuild && lastError) {
				// Tests/build passed — mark issue as potentially resolved
				const issue = state.issues.get(lastError);
				if (issue) {
					ctx.ui.setWidget("debug", [], { placement: "belowEditor" });
					state.isDebugging = false;
					lastError = null;
					persistState();
				}
			}
		}
	});

	// Track write/edit as fix attempts when debugging
	pi.on("tool_call", async (event, ctx) => {
		if (!state.isDebugging || !lastError) return;

		if (event.toolName === "write" || event.toolName === "edit") {
			writesSinceLastError++;

			// After a write during debugging, count it as a fix attempt
			const issue = state.issues.get(lastError);
			if (issue) {
				issue.attempts++;
				state.totalAttempts++;

				if (issue.attempts >= 3 && !issue.escalated) {
					issue.escalated = true;
					persistState();

					ctx.ui.notify(
						[
							`⚠ ${issue.attempts} fix attempts for the same error.`,
							"",
							`Error: ${issue.signature.slice(0, 100)}`,
							"",
							"STOP and reconsider:",
							"• Is this the right approach?",
							"• Are you fixing the root cause or a symptom?",
							"• Should you read the systematic-debugging skill?",
							"• Would it help to trace the error backward through the call chain?",
						].join("\n"),
						"warning",
					);

					return; // Don't block, just warn strongly
				}

				persistState();
			}
		}
	});

	pi.registerCommand("debug-status", {
		description: "Show debugging session status and fix attempts",
		handler: async (_args, ctx) => {
			if (state.issues.size === 0) {
				ctx.ui.notify("No debugging issues tracked in this session.", "info");
				return;
			}

			const lines: string[] = ["═══ Debug Status ═══"];
			lines.push(`Active debugging: ${state.isDebugging ? "yes" : "no"}`);
			lines.push(`Total fix attempts: ${state.totalAttempts}`);
			lines.push(`Issues tracked: ${state.issues.size}`);
			lines.push("");

			for (const [sig, issue] of state.issues) {
				const icon = issue.escalated ? "🔴" : issue.attempts >= 2 ? "🟡" : "🟢";
				lines.push(`${icon} ${sig.slice(0, 80)}`);
				lines.push(`   Attempts: ${issue.attempts} | Commands tried: ${issue.commands.length}`);
				const elapsed = Math.round((Date.now() - issue.firstSeen) / 60000);
				lines.push(`   First seen: ${elapsed}m ago`);
			}

			ctx.ui.notify(lines.join("\n"), "info");
		},
	});

	pi.registerCommand("debug-reset", {
		description: "Reset debugging state",
		handler: async (_args, ctx) => {
			state = { issues: new Map(), totalAttempts: 0, isDebugging: false };
			lastError = null;
			writesSinceLastError = 0;
			ctx.ui.setWidget("debug", [], { placement: "belowEditor" });
			ctx.ui.notify("Debug state cleared.", "info");
		},
	});
}
