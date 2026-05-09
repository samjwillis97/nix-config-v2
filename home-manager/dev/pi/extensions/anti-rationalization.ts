/**
 * Anti-Rationalization Extension
 *
 * Detects when the LLM is making excuses to skip required workflows.
 * Tracks rationalization patterns and warns the user.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

interface RationalizationEntry {
	phrase: string;
	context: string;
	timestamp: number;
	category: string;
}

// Rationalization patterns grouped by category
const RATIONALIZATION_PATTERNS: Array<{ category: string; patterns: RegExp[]; counter: string }> = [
	{
		category: "skipping-design",
		patterns: [
			/\b(?:simple|straightforward|obvious)\s+enough\s+(?:to|that)\s+(?:just|skip|go\s+ahead)/i,
			/\bdon'?t\s+(?:need|require)\s+(?:a\s+)?(?:design|brainstorm|plan)\b/i,
			/\b(?:let'?s\s+)?(?:just\s+)?(?:jump|dive|go)\s+(?:straight\s+)?(?:in|into|to)\s+(?:coding|implementation|code)/i,
			/\b(?:no\s+need|unnecessary)\s+to\s+(?:brainstorm|design|plan)\b/i,
		],
		counter: "Every change benefits from at least a brief plan. What's the approach?",
	},
	{
		category: "skipping-tests",
		patterns: [
			/\b(?:tests?\s+(?:aren'?t|are\s+not|would\s+be)\s+(?:necessary|needed|required|useful))\b/i,
			/\b(?:too\s+(?:trivial|simple)\s+to\s+test)\b/i,
			/\b(?:testing\s+(?:this|that|it)\s+(?:would|is)\s+(?:be\s+)?(?:overkill|excessive))\b/i,
			/\b(?:we\s+can\s+(?:skip|forego|omit)\s+(?:the\s+)?tests?)\b/i,
			/\b(?:no\s+test\s+(?:framework|infrastructure)\s+(?:set\s+up|available|configured))\b/i,
		],
		counter: "Tests are part of the work. If there's no test infrastructure, set it up.",
	},
	{
		category: "skipping-verification",
		patterns: [
			/\bthat\s+should\s+(?:work|do\s+it|be\s+(?:fine|correct|enough))\b/i,
			/\bprobably\s+(?:works?|fine|correct|good)\b/i,
			/\bI\s+(?:believe|think|expect|assume)\s+(?:this|that|it)\s+(?:will\s+)?work/i,
			/\bseems?\s+(?:to\s+)?(?:work|be\s+(?:fine|correct|working))\b/i,
			/\blikely\s+(?:works?|correct|fine)\b/i,
			/\bshould\s+be\s+(?:all\s+)?(?:good|set|fine|ready)\b/i,
		],
		counter: "Don't guess — run the verification and show the output.",
	},
	{
		category: "skipping-review",
		patterns: [
			/\b(?:code\s+)?review\s+(?:isn'?t|is\s+not)\s+(?:necessary|needed)\b/i,
			/\b(?:small|minor|tiny)\s+(?:enough\s+)?(?:change\s+)?(?:to\s+skip|that\s+(?:doesn'?t|does\s+not)\s+(?:need|require))\s+review/i,
		],
		counter: "Even small changes benefit from a second look.",
	},
	{
		category: "rushing",
		patterns: [
			/\b(?:in\s+the\s+interest\s+of\s+(?:time|speed|efficiency))\b/i,
			/\b(?:to\s+(?:save|speed\s+up|expedite))\b.*\b(?:skip|omit|forego)\b/i,
			/\b(?:let'?s\s+)?(?:quickly|fast|rapidly)\s+(?:just\s+)?(?:do|make|implement)\b/i,
		],
		counter: "Rushing causes rework. Following the process is faster in the long run.",
	},
];

export default function (pi: ExtensionAPI) {
	let history: RationalizationEntry[] = [];
	let rationalizationsThisTurn = 0;

	pi.on("session_start", async (_event, ctx) => {
		history = [];

		// Restore from session
		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type === "custom" && entry.customType === "superpowers:rationalization") {
				const data = entry.data as RationalizationEntry;
				if (data) history.push(data);
			}
		}
	});

	pi.on("turn_start", async () => {
		rationalizationsThisTurn = 0;
	});

	pi.on("message_end", async (event, ctx) => {
		if (event.message.role !== "assistant") return;

		const text = event.message.content
			.filter((c): c is { type: "text"; text: string } => c.type === "text")
			.map((c) => c.text)
			.join(" ");

		const detected: Array<{ category: string; phrase: string; counter: string }> = [];

		for (const group of RATIONALIZATION_PATTERNS) {
			for (const pattern of group.patterns) {
				const match = text.match(pattern);
				if (match) {
					detected.push({
						category: group.category,
						phrase: match[0],
						counter: group.counter,
					});

					history.push({
						phrase: match[0],
						context: text.slice(Math.max(0, match.index! - 50), match.index! + match[0].length + 50),
						timestamp: Date.now(),
						category: group.category,
					});

					pi.appendEntry("superpowers:rationalization", {
						phrase: match[0],
						context: text.slice(Math.max(0, match.index! - 50), match.index! + match[0].length + 50),
						timestamp: Date.now(),
						category: group.category,
					});

					break; // One match per category is enough
				}
			}
		}

		if (detected.length > 0) {
			rationalizationsThisTurn += detected.length;

			const warnings = detected.map(
				(d) => `⚠ Detected rationalization (${d.category}): "${d.phrase}"\n  → ${d.counter}`,
			);

			ctx.ui.notify(warnings.join("\n\n"), "warning");

			// If multiple rationalizations in one turn, it's a pattern
			if (rationalizationsThisTurn >= 2) {
				ctx.ui.notify(
					"🔴 Multiple rationalizations detected in this turn. The agent may be trying to shortcut the process.",
					"warning",
				);
			}

			// Inject a steering message to course-correct
			if (detected.some((d) => d.category === "skipping-verification")) {
				pi.sendMessage(
					{
						customType: "superpowers:correction",
						content:
							"IMPORTANT: You used hedging language. Do not claim completion without running actual verification commands and reading their output.",
						display: false,
					},
					{ deliverAs: "steer" },
				);
			}
		}
	});

	pi.registerCommand("rationalizations", {
		description: "Show history of detected rationalization attempts",
		handler: async (_args, ctx) => {
			if (history.length === 0) {
				ctx.ui.notify("No rationalizations detected in this session. 🎉", "success");
				return;
			}

			const lines: string[] = ["═══ Rationalization History ═══"];
			lines.push(`Total detected: ${history.length}`);
			lines.push("");

			// Group by category
			const byCategory = new Map<string, RationalizationEntry[]>();
			for (const entry of history) {
				if (!byCategory.has(entry.category)) byCategory.set(entry.category, []);
				byCategory.get(entry.category)!.push(entry);
			}

			for (const [category, entries] of byCategory) {
				lines.push(`── ${category} (${entries.length}x) ──`);
				for (const entry of entries.slice(-3)) {
					const ago = Math.round((Date.now() - entry.timestamp) / 60000);
					lines.push(`  "${entry.phrase}" — ${ago}m ago`);
				}
				lines.push("");
			}

			ctx.ui.notify(lines.join("\n"), "info");
		},
	});
}
