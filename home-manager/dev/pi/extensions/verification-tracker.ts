/**
 * Verification Tracker Extension
 *
 * Tracks whether tests/builds were run before completion claims.
 * When the agent claims completion without evidence, or uses hedging
 * language, injects steering messages to guide it back to verification.
 * No UI — purely agent-facing guidance.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isBashToolResult } from "@mariozechner/pi-coding-agent";

interface VerificationState {
	testsRun: boolean;
	testsPassed: number;
	testsFailed: number;
	buildRun: boolean;
	buildPassed: boolean;
	lastVerifiedAt: number | null;
	turnsSinceVerification: number;
}

const TEST_PATTERNS = [
	/(\d+)\s+(?:tests?\s+)?passed/i,
	/(\d+)\s+(?:tests?\s+)?failed/i,
	/Tests:\s+(\d+)\s+passed/i,
	/Tests:\s+(\d+)\s+failed/i,
	/(\d+)\s+passing/i,
	/(\d+)\s+failing/i,
	/PASS\s/,
	/FAIL\s/,
	/ok\s+\d+\s+tests/i,
	/FAILED\s+\d+\s+tests/i,
	/test result:\s+(ok|FAILED)/,
	/pytest.*(\d+) passed/i,
	/pytest.*(\d+) failed/i,
	/--- PASS:/,
	/--- FAIL:/,
	/All \d+ tests passed/i,
	/\d+ tests?, \d+ assertions?/i,
	/nix-build.*succeeded/i,
	/nix build.*succeeded/i,
	/build successful/i,
	/✓|✗|✘/,
];

const TEST_RUNNER_COMMANDS = [
	/\b(jest|vitest|mocha|pytest|cargo\s+test|go\s+test|mix\s+test|rspec|phpunit|dotnet\s+test|gradle\s+test|mvn\s+test|npm\s+test|yarn\s+test|pnpm\s+test|bun\s+test|nix\s+flake\s+check|nix-build)\b/i,
];

const BUILD_COMMANDS = [
	/\b(npm\s+run\s+build|yarn\s+build|pnpm\s+build|cargo\s+build|go\s+build|make\b|gradle\s+build|mvn\s+(?:compile|package)|dotnet\s+build|nix\s+build|nix-build|tsc\b)\b/i,
];

const COMPLETION_PHRASES = [
	/\b(?:done|completed|finished|implemented|fixed|resolved|ready|all\s+set)\b/i,
	/\bthat\s+should\s+(?:do\s+it|work|be\s+(?:it|everything))\b/i,
	/\bchanges?\s+(?:are|have\s+been)\s+(?:made|applied|complete)/i,
	/\bsuccessfully\s+(?:implemented|created|updated|fixed|added)/i,
];

const WEASEL_WORDS = [
	/\bshould\s+(?:work|be\s+fine|be\s+correct|do\s+it|fix)\b/i,
	/\bprobably\s+(?:works?|fine|correct|fixed)\b/i,
	/\bI\s+believe\s+(?:this|that|it)\s+(?:works?|should|is\s+correct)/i,
	/\bseems?\s+to\s+(?:work|be\s+(?:fine|correct|working))\b/i,
	/\blikely\s+(?:works?|correct|fine)\b/i,
];

function parseTestOutput(output: string): { passed: number; failed: number } {
	let passed = 0;
	let failed = 0;

	const jestMatch = output.match(/Tests:\s+(?:(\d+)\s+failed,?\s*)?(?:(\d+)\s+passed)?/i);
	if (jestMatch) {
		failed = parseInt(jestMatch[1] || "0");
		passed = parseInt(jestMatch[2] || "0");
		return { passed, failed };
	}

	const mochaPass = output.match(/(\d+)\s+passing/i);
	const mochaFail = output.match(/(\d+)\s+failing/i);
	if (mochaPass) passed = parseInt(mochaPass[1]);
	if (mochaFail) failed = parseInt(mochaFail[1]);
	if (mochaPass || mochaFail) return { passed, failed };

	const pytestPass = output.match(/(\d+)\s+passed/i);
	const pytestFail = output.match(/(\d+)\s+failed/i);
	if (pytestPass) passed = parseInt(pytestPass[1]);
	if (pytestFail) failed = parseInt(pytestFail[1]);
	if (pytestPass || pytestFail) return { passed, failed };

	const goPass = (output.match(/--- PASS:/g) || []).length;
	const goFail = (output.match(/--- FAIL:/g) || []).length;
	if (goPass || goFail) return { passed: goPass, failed: goFail };

	const rustMatch = output.match(/test result:.*?(\d+)\s+passed.*?(\d+)\s+failed/i);
	if (rustMatch) {
		return { passed: parseInt(rustMatch[1]), failed: parseInt(rustMatch[2]) };
	}

	const checkPassed = (output.match(/✓/g) || []).length;
	const checkFailed = (output.match(/[✗✘]/g) || []).length;
	if (checkPassed || checkFailed) return { passed: checkPassed, failed: checkFailed };

	return { passed: 0, failed: 0 };
}

function isTestCommand(command: string): boolean {
	return TEST_RUNNER_COMMANDS.some((p) => p.test(command));
}

function isBuildCommand(command: string): boolean {
	return BUILD_COMMANDS.some((p) => p.test(command));
}

function hasTestOutput(output: string): boolean {
	return TEST_PATTERNS.some((p) => p.test(output));
}

export default function (pi: ExtensionAPI) {
	let state: VerificationState = {
		testsRun: false,
		testsPassed: 0,
		testsFailed: 0,
		buildRun: false,
		buildPassed: false,
		lastVerifiedAt: null,
		turnsSinceVerification: 0,
	};

	function resetState() {
		state = {
			testsRun: false,
			testsPassed: 0,
			testsFailed: 0,
			buildRun: false,
			buildPassed: false,
			lastVerifiedAt: null,
			turnsSinceVerification: 0,
		};
	}

	pi.on("session_start", async (_event, ctx) => {
		resetState();

		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type === "custom" && entry.customType === "superpowers:verification") {
				const data = entry.data as VerificationState;
				if (data) state = { ...state, ...data };
			}
		}
	});

	pi.on("turn_start", async (_event, _ctx) => {
		state.turnsSinceVerification++;
	});

	pi.on("tool_result", async (event, _ctx) => {
		if (!isBashToolResult(event)) return;

		const command = (event.input as any)?.command || "";
		const output = event.content
			.filter((c): c is { type: "text"; text: string } => c.type === "text")
			.map((c) => c.text)
			.join("\n");

		if (isTestCommand(command) || hasTestOutput(output)) {
			state.testsRun = true;
			const results = parseTestOutput(output);
			state.testsPassed = results.passed;
			state.testsFailed = results.failed;
			state.lastVerifiedAt = Date.now();
			state.turnsSinceVerification = 0;
			pi.appendEntry("superpowers:verification", { ...state });
		}

		if (isBuildCommand(command)) {
			state.buildRun = true;
			state.buildPassed = !event.isError;
			state.lastVerifiedAt = Date.now();
			state.turnsSinceVerification = 0;
			pi.appendEntry("superpowers:verification", { ...state });
		}
	});

	pi.on("message_end", async (event, _ctx) => {
		if (event.message.role !== "assistant") return;

		const text = event.message.content
			.filter((c): c is { type: "text"; text: string } => c.type === "text")
			.map((c) => c.text)
			.join(" ");

		const isCompletion = COMPLETION_PHRASES.some((p) => p.test(text));
		const hasWeaselWords = WEASEL_WORDS.some((p) => p.test(text));

		// Steer the agent back to verification when it claims completion without evidence
		if (isCompletion && !state.testsRun && state.turnsSinceVerification > 0) {
			pi.sendMessage(
				{
					customType: "superpowers:verification-nudge",
					content: [
						"VERIFICATION REQUIRED: You claimed completion but no tests or build commands were run this session.",
						"Before finalising, you must:",
						"1. Run the relevant test suite and show the output",
						"2. Run the build if applicable and show the output",
						"3. Demonstrate the change works with concrete evidence",
						"Do not use hedging language like 'should work' — show actual results.",
					].join("\n"),
					display: false,
				},
				{ deliverAs: "steer" },
			);
		}

		if (hasWeaselWords) {
			pi.sendMessage(
				{
					customType: "superpowers:verification-nudge",
					content: [
						'HEDGING DETECTED: You used uncertain language ("should work", "probably fine", etc.).',
						"Replace hedging with evidence. Run the actual commands and report their output.",
						"If you cannot verify right now, say so explicitly rather than guessing.",
					].join("\n"),
					display: false,
				},
				{ deliverAs: "steer" },
			);
		}
	});
}
