/**
 * Plan Mode Extension
 *
 * Structured plan creation and execution tracking.
 * Plans are stored as session entries AND written to docs/plans/.
 * The agent uses the plan tool to create, update, and track progress.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type, type Static } from "typebox";
import { StringEnum } from "@earendil-works/pi-ai";

interface PlanStep {
	id: number;
	description: string;
	files: string[];
	verification: string;
	status: "pending" | "in-progress" | "done" | "failed" | "skipped";
	notes: string;
}

interface Plan {
	name: string;
	goal: string;
	steps: PlanStep[];
	createdAt: number;
	updatedAt: number;
}

const PlanParams = Type.Object({
	action: StringEnum(["create", "update-step", "show", "add-step", "remove-step"] as const, {
		description: "Action to perform on the plan",
	}),
	name: Type.Optional(Type.String({ description: "Plan name (for create)" })),
	goal: Type.Optional(Type.String({ description: "Plan goal (for create)" })),
	steps: Type.Optional(
		Type.Array(
			Type.Object({
				description: Type.String(),
				files: Type.Optional(Type.Array(Type.String())),
				verification: Type.Optional(Type.String()),
			}),
			{ description: "Steps (for create)" },
		),
	),
	stepId: Type.Optional(Type.Number({ description: "Step ID (for update-step)" })),
	status: Type.Optional(
		StringEnum(["pending", "in-progress", "done", "failed", "skipped"] as const, {
			description: "Step status (for update-step)",
		}),
	),
	notes: Type.Optional(Type.String({ description: "Notes for a step update, or description for add-step" })),
	verification: Type.Optional(Type.String({ description: "Verification command for add-step" })),
	files: Type.Optional(Type.Array(Type.String(), { description: "Files for add-step" })),
});

function formatPlan(plan: Plan): string {
	const lines: string[] = [];
	lines.push(`# Plan: ${plan.name}`);
	lines.push("");
	lines.push(`**Goal:** ${plan.goal}`);
	lines.push("");

	const done = plan.steps.filter((s) => s.status === "done").length;
	const total = plan.steps.length;
	lines.push(`**Progress:** ${done}/${total} steps complete`);
	lines.push("");

	for (const step of plan.steps) {
		const icon =
			step.status === "done"
				? "✅"
				: step.status === "in-progress"
					? "🔨"
					: step.status === "failed"
						? "❌"
						: step.status === "skipped"
							? "⏭"
							: "⬜";
		lines.push(`${icon} **Step ${step.id}:** ${step.description}`);
		if (step.files.length > 0) {
			lines.push(`   Files: ${step.files.join(", ")}`);
		}
		if (step.verification) {
			lines.push(`   Verify: \`${step.verification}\``);
		}
		if (step.notes) {
			lines.push(`   Notes: ${step.notes}`);
		}
	}

	return lines.join("\n");
}

function writePlanToDisk(plan: Plan, cwd: string) {
	try {
		const dir = path.join(cwd, "docs", "plans");
		fs.mkdirSync(dir, { recursive: true });
		const safeName = plan.name.replace(/[^\w.-]+/g, "-").toLowerCase();
		const date = new Date().toISOString().split("T")[0];
		const filePath = path.join(dir, `${date}-${safeName}.md`);
		fs.writeFileSync(filePath, formatPlan(plan), "utf-8");
	} catch {
		// Best effort — don't fail if we can't write
	}
}

export default function (pi: ExtensionAPI) {
	let activePlan: Plan | null = null;

	function persistPlan() {
		if (activePlan) {
			activePlan.updatedAt = Date.now();
			pi.appendEntry("superpowers:plan", { ...activePlan });
		}
	}

	pi.on("session_start", async (_event, ctx) => {
		activePlan = null;

		// Restore from session
		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type === "custom" && entry.customType === "superpowers:plan") {
				activePlan = entry.data as Plan;
			}
		}
	});

	pi.registerTool({
		name: "plan",
		label: "Plan",
		description: [
			"Create and manage implementation plans with trackable steps.",
			"Actions: create (new plan), update-step (change step status), show (display plan),",
			"add-step (add a step), remove-step (remove a step).",
			"Each step should be a small, verifiable unit of work (2-5 minutes).",
			"Update step status as you work: pending → in-progress → done/failed/skipped.",
		].join(" "),
		parameters: PlanParams,

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			switch (params.action) {
				case "create": {
					if (!params.name || !params.goal || !params.steps?.length) {
						return {
							content: [{ type: "text", text: "Error: create requires name, goal, and steps" }],
							details: {},
							isError: true,
						};
					}

					activePlan = {
						name: params.name,
						goal: params.goal,
						steps: params.steps.map((s, i) => ({
							id: i + 1,
							description: s.description,
							files: s.files || [],
							verification: s.verification || "",
							status: "pending" as const,
							notes: "",
						})),
						createdAt: Date.now(),
						updatedAt: Date.now(),
					};

					persistPlan();
					writePlanToDisk(activePlan, ctx.cwd);

					return {
						content: [{ type: "text", text: formatPlan(activePlan) }],
						details: { plan: activePlan },
					};
				}

				case "update-step": {
					if (!activePlan) {
						return {
							content: [{ type: "text", text: "No active plan. Create one first." }],
							details: {},
							isError: true,
						};
					}

					const step = activePlan.steps.find((s) => s.id === params.stepId);
					if (!step) {
						return {
							content: [{ type: "text", text: `Step ${params.stepId} not found.` }],
							details: {},
							isError: true,
						};
					}

					if (params.status) step.status = params.status;
					if (params.notes) step.notes = params.notes;

					persistPlan();
					writePlanToDisk(activePlan, ctx.cwd);

					return {
						content: [{ type: "text", text: formatPlan(activePlan) }],
						details: { plan: activePlan },
					};
				}

				case "add-step": {
					if (!activePlan) {
						return {
							content: [{ type: "text", text: "No active plan. Create one first." }],
							details: {},
							isError: true,
						};
					}

					const newId = Math.max(0, ...activePlan.steps.map((s) => s.id)) + 1;
					activePlan.steps.push({
						id: newId,
						description: params.notes || "New step",
						files: params.files || [],
						verification: params.verification || "",
						status: "pending",
						notes: "",
					});

					persistPlan();
					writePlanToDisk(activePlan, ctx.cwd);

					return {
						content: [{ type: "text", text: formatPlan(activePlan) }],
						details: { plan: activePlan },
					};
				}

				case "remove-step": {
					if (!activePlan) {
						return {
							content: [{ type: "text", text: "No active plan. Create one first." }],
							details: {},
							isError: true,
						};
					}

					activePlan.steps = activePlan.steps.filter((s) => s.id !== params.stepId);
					// Re-number
					activePlan.steps.forEach((s, i) => (s.id = i + 1));

					persistPlan();
					writePlanToDisk(activePlan, ctx.cwd);

					return {
						content: [{ type: "text", text: formatPlan(activePlan) }],
						details: { plan: activePlan },
					};
				}

				case "show": {
					if (!activePlan) {
						return {
							content: [{ type: "text", text: "No active plan." }],
							details: {},
						};
					}

					return {
						content: [{ type: "text", text: formatPlan(activePlan) }],
						details: { plan: activePlan },
					};
				}

				default: {
					return {
						content: [{ type: "text", text: "Unknown action. Use: create, update-step, show, add-step, remove-step" }],
						details: {},
						isError: true,
					};
				}
			}
		},
	});

	pi.registerCommand("plan", {
		description: "Show the active plan",
		handler: async (_args, ctx) => {
			if (!activePlan) {
				ctx.ui.notify("No active plan. Ask the agent to create one.", "info");
				return;
			}
			ctx.ui.notify(formatPlan(activePlan), "info");
		},
	});

	pi.registerCommand("plan-reset", {
		description: "Clear the active plan",
		handler: async (_args, ctx) => {
			activePlan = null;
			pi.appendEntry("superpowers:plan", null);
			ctx.ui.notify("Plan cleared.", "info");
		},
	});
}
