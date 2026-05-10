/**
 * Session Auto-Naming Extension
 *
 * Automatically names sessions after the first agent response using a quick LLM call.
 * Also provides /session-name [name] to set or show the name manually.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { complete, getModel } from "@earendil-works/pi-ai";

export default function (pi: ExtensionAPI) {
	let hasNamed = false;

	pi.on("session_start", async () => {
		hasNamed = !!pi.getSessionName();
	});

	pi.on("agent_end", async (event, ctx) => {
		if (hasNamed || !ctx.model) return;

		// Find the first user message from this exchange
		const userMsg = event.messages.find((m) => m.role === "user");
		if (!userMsg) return;

		const rawContent = userMsg.content;
		const userText =
			typeof rawContent === "string"
				? rawContent
				: rawContent
						.filter(
							(c): c is { type: "text"; text: string } => c.type === "text",
						)
						.map((c) => c.text)
						.join(" ");

		if (!userText.trim()) return;

		hasNamed = true;

		try {
			// Try cheap models first, fall back to current model
			const candidates = [
				getModel("github-copilot", "claude-haiku-4.5"),
				getModel("anthropic", "claude-haiku-4-5"),
				ctx.model,
			].filter((m) => m != null);

			let namingModel = ctx.model;
			for (const candidate of candidates) {
				const auth = await ctx.modelRegistry.getApiKeyAndHeaders(candidate);
				if (auth.ok && auth.apiKey) {
					namingModel = candidate;
					break;
				}
			}

			const auth = await ctx.modelRegistry.getApiKeyAndHeaders(namingModel);
			if (!auth.ok || !auth.apiKey) return;

			const response = await complete(
				namingModel,
				{
					systemPrompt:
						"Generate a short session name (3-6 words, no quotes, no punctuation) that summarizes the user's request. Reply with ONLY the name, nothing else.",
					messages: [
						{
							role: "user",
							content: [{ type: "text", text: userText.slice(0, 500) }],
							timestamp: Date.now(),
						},
					],
				},
				{ apiKey: auth.apiKey, headers: auth.headers },
			);

			const name = response.content
				.filter((c): c is { type: "text"; text: string } => c.type === "text")
				.map((c) => c.text)
				.join("")
				.trim();

			if (name && name.length < 60) {
				pi.setSessionName(name);
			}
		} catch {
			// Silent fail — naming is best-effort
		}
	});

	pi.registerCommand("session-name", {
		description: "Set or show session name (usage: /session-name [new name])",
		handler: async (args, ctx) => {
			const name = args.trim();

			if (name) {
				pi.setSessionName(name);
				hasNamed = true;
				ctx.ui.notify(`Session named: ${name}`, "info");
			} else {
				const current = pi.getSessionName();
				ctx.ui.notify(
					current ? `Session: ${current}` : "No session name set",
					"info",
				);
			}
		},
	});
}
