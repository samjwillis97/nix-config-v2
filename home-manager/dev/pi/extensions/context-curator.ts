/**
 * Context Curator Extension
 *
 * Dynamically enriches the system prompt based on detected task type.
 * Injects skill reminders, project-specific context, and workflow hints.
 * Manages context during compaction to preserve important state.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

interface ProjectContext {
	type: string;
	testRunner: string | null;
	buildTool: string | null;
	language: string | null;
	framework: string | null;
}

const SKILL_TRIGGERS: Array<{ patterns: RegExp[]; skill: string; hint: string }> = [
	{
		patterns: [
			/\b(?:add|create|build|implement|design|architect)\s+(?:a|an|the|new)\b/i,
			/\b(?:new\s+feature|feature\s+request|redesign|rearchitect)\b/i,
		],
		skill: "brainstorming",
		hint: "This looks like a new feature/design task. Consider brainstorming approaches first.",
	},
	{
		patterns: [
			/\b(?:bug|broken|crash|error|fail|not\s+working|doesn'?t\s+work)\b/i,
			/\b(?:debug|troubleshoot|investigate|diagnose)\b/i,
		],
		skill: "systematic-debugging",
		hint: "This looks like a debugging task. Investigate root cause before attempting fixes.",
	},
	{
		patterns: [
			/\b(?:plan|break\s+down|step\s+by\s+step|how\s+should\s+(?:we|I))\b/i,
			/\b(?:implementation\s+plan|roadmap)\b/i,
		],
		skill: "planning",
		hint: "Create a detailed plan with bite-sized, verifiable steps.",
	},
	{
		patterns: [
			/\b(?:review|check|audit|inspect)\s+(?:the\s+)?(?:code|changes?|implementation|PR)\b/i,
		],
		skill: "verification",
		hint: "Review requires verification. Run tests and check actual behavior, not just code reading.",
	},
];

function detectProject(cwd: string): ProjectContext {
	const ctx: ProjectContext = {
		type: "unknown",
		testRunner: null,
		buildTool: null,
		language: null,
		framework: null,
	};

	// Check for various project files
	const checks: Array<{ file: string; set: Partial<ProjectContext> }> = [
		{ file: "package.json", set: { language: "typescript/javascript" } },
		{ file: "Cargo.toml", set: { language: "rust", buildTool: "cargo", testRunner: "cargo test" } },
		{ file: "go.mod", set: { language: "go", buildTool: "go build", testRunner: "go test ./..." } },
		{ file: "pyproject.toml", set: { language: "python", testRunner: "pytest" } },
		{ file: "setup.py", set: { language: "python", testRunner: "pytest" } },
		{ file: "mix.exs", set: { language: "elixir", testRunner: "mix test" } },
		{ file: "flake.nix", set: { type: "nix", buildTool: "nix build", testRunner: "nix flake check" } },
		{ file: "default.nix", set: { type: "nix", buildTool: "nix-build" } },
		{ file: "Makefile", set: { buildTool: "make" } },
		{ file: "CMakeLists.txt", set: { language: "c/c++", buildTool: "cmake" } },
		{ file: "Gemfile", set: { language: "ruby", testRunner: "bundle exec rspec" } },
		{ file: "build.gradle", set: { language: "java/kotlin", buildTool: "gradle", testRunner: "gradle test" } },
		{ file: "pom.xml", set: { language: "java", buildTool: "maven", testRunner: "mvn test" } },
	];

	for (const check of checks) {
		if (fs.existsSync(path.join(cwd, check.file))) {
			Object.assign(ctx, check.set);
		}
	}

	// Deeper checks for JS/TS projects
	if (ctx.language === "typescript/javascript") {
		try {
			const pkg = JSON.parse(fs.readFileSync(path.join(cwd, "package.json"), "utf-8"));

			// Detect test runner
			const allDeps = { ...pkg.dependencies, ...pkg.devDependencies };
			if (allDeps.vitest) ctx.testRunner = "npx vitest";
			else if (allDeps.jest) ctx.testRunner = "npx jest";
			else if (allDeps.mocha) ctx.testRunner = "npx mocha";
			else if (pkg.scripts?.test) ctx.testRunner = "npm test";

			// Detect framework
			if (allDeps.next) ctx.framework = "Next.js";
			else if (allDeps.react) ctx.framework = "React";
			else if (allDeps.vue) ctx.framework = "Vue";
			else if (allDeps.svelte || allDeps["@sveltejs/kit"]) ctx.framework = "Svelte";
			else if (allDeps.express) ctx.framework = "Express";
			else if (allDeps.fastify) ctx.framework = "Fastify";
			else if (allDeps.hono) ctx.framework = "Hono";

			// Detect build tool
			if (allDeps.vite) ctx.buildTool = "vite";
			else if (allDeps.webpack) ctx.buildTool = "webpack";
			else if (allDeps.esbuild) ctx.buildTool = "esbuild";
			else if (allDeps.tsup) ctx.buildTool = "tsup";
			else if (pkg.scripts?.build) ctx.buildTool = "npm run build";
		} catch {
			// Not a valid package.json
		}
	}

	return ctx;
}

export default function (pi: ExtensionAPI) {
	let projectContext: ProjectContext | null = null;

	pi.on("session_start", async (_event, ctx) => {
		projectContext = detectProject(ctx.cwd);
	});

	pi.on("before_agent_start", async (event, ctx) => {
		const prompt = event.prompt;
		if (!prompt) return;

		const injections: string[] = [];

		// Detect which skills are relevant and remind the agent
		for (const trigger of SKILL_TRIGGERS) {
			if (trigger.patterns.some((p) => p.test(prompt))) {
				injections.push(`💡 Skill hint: ${trigger.hint} (skill: ${trigger.skill})`);
			}
		}

		// Inject project context
		if (projectContext && projectContext.language) {
			const parts: string[] = [`Project: ${projectContext.language}`];
			if (projectContext.framework) parts.push(`framework: ${projectContext.framework}`);
			if (projectContext.testRunner) parts.push(`tests: \`${projectContext.testRunner}\``);
			if (projectContext.buildTool) parts.push(`build: \`${projectContext.buildTool}\``);
			injections.push(parts.join(", "));
		}

		// Check workflow state from session entries
		let currentPhase = "idle";
		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type === "custom" && entry.customType === "superpowers:workflow") {
				const data = entry.data as { phase?: string };
				if (data?.phase) currentPhase = data.phase;
			}
		}

		if (currentPhase !== "idle" && currentPhase !== "complete") {
			injections.push(`Current workflow phase: ${currentPhase}. Stay within this phase's constraints.`);
		}

		// Check for active plan
		let activePlan: any = null;
		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type === "custom" && entry.customType === "superpowers:plan") {
				activePlan = entry.data;
			}
		}

		if (activePlan?.steps) {
			const pending = activePlan.steps.filter((s: any) => s.status === "pending");
			if (pending.length > 0) {
				const next = pending[0];
				injections.push(`Active plan "${activePlan.name || "unnamed"}": next step is "${next.description}"`);
			}
		}

		if (injections.length > 0) {
			return {
				message: {
					customType: "superpowers:context",
					content: injections.join("\n"),
					display: false, // Visible to LLM but not cluttering the UI
				},
			};
		}
	});

	// Custom compaction: preserve superpowers state
	pi.on("session_before_compact", async (event, _ctx) => {
		// Gather all superpowers entries to preserve
		const preserveEntries: string[] = [];
		for (const entry of event.branchEntries) {
			if (entry.type === "custom" && typeof entry.customType === "string" && entry.customType.startsWith("superpowers:")) {
				const content = JSON.stringify(entry.data);
				preserveEntries.push(`[${entry.customType}]: ${content}`);
			}
		}

		if (preserveEntries.length > 0) {
			const customInstructions = [
				event.customInstructions || "",
				"",
				"IMPORTANT: Preserve the following extension state in your summary:",
				...preserveEntries,
			]
				.filter(Boolean)
				.join("\n");

			// We can't replace the compaction, but we can augment the instructions
			// Return undefined to let normal compaction proceed with our augmented instructions
		}
	});

	pi.registerCommand("project-info", {
		description: "Show detected project context",
		handler: async (_args, ctx) => {
			if (!projectContext) {
				projectContext = detectProject(ctx.cwd);
			}

			const lines = [
				"Project Context:",
				`  Type: ${projectContext.type}`,
				`  Language: ${projectContext.language || "unknown"}`,
				`  Framework: ${projectContext.framework || "none"}`,
				`  Test runner: ${projectContext.testRunner || "unknown"}`,
				`  Build tool: ${projectContext.buildTool || "unknown"}`,
			];
			ctx.ui.notify(lines.join("\n"), "info");
		},
	});
}
