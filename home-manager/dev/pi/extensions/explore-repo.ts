/**
 * Resolve Repo Extension - Resolve external repositories to local paths
 *
 * Provides:
 *   - resolve_repo tool: resolves owner/repo to a local filesystem path
 *   - /repo-daemon command: check daemon status and list branches
 *
 * Handles finding repos via:
 *   1. repo-daemon Unix socket (asks host to clone with full auth)
 *   2. Local ~/code lookup (f's managed worktrees, read-only)
 */

import * as fs from "node:fs";
import * as net from "node:net";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const CODE_ROOT = path.join(os.homedir(), "code");
const GIT_DOMAIN = "github.com";
const SOCKET_PATH = path.join(os.homedir(), ".pi", "agent", "repo-daemon.sock");

/**
 * Send a request to the repo-daemon over Unix socket.
 * Returns the response or null if the daemon is unavailable.
 */
function daemonRequest(
	request: Record<string, unknown>,
	timeoutMs = 60000,
): Promise<{
	ok: boolean;
	path?: string;
	source?: string;
	error?: string;
	branches?: string[];
} | null> {
	return new Promise((resolve) => {
		if (!fs.existsSync(SOCKET_PATH)) {
			resolve(null);
			return;
		}

		const client = net.createConnection(SOCKET_PATH);
		let buffer = "";
		let settled = false;

		const timeout = setTimeout(() => {
			if (!settled) {
				settled = true;
				client.destroy();
				resolve(null);
			}
		}, timeoutMs);

		client.on("connect", () => {
			client.write(JSON.stringify(request) + "\n");
		});

		client.on("data", (chunk) => {
			buffer += chunk.toString();
			const newlineIdx = buffer.indexOf("\n");
			if (newlineIdx !== -1) {
				const line = buffer.slice(0, newlineIdx).trim();
				if (!settled) {
					settled = true;
					clearTimeout(timeout);
					client.destroy();
					try {
						resolve(JSON.parse(line));
					} catch {
						resolve(null);
					}
				}
			}
		});

		client.on("error", () => {
			if (!settled) {
				settled = true;
				clearTimeout(timeout);
				resolve(null);
			}
		});
	});
}

/**
 * Find an existing repo checkout in ~/code managed by f.
 * f's structure: ~/code/github.com/owner/repo/branch/
 */
function findLocalRepo(
	owner: string,
	repo: string,
	branch?: string,
): string | null {
	const repoDir = path.join(CODE_ROOT, GIT_DOMAIN, owner, repo);

	if (!fs.existsSync(repoDir)) return null;

	if (branch) {
		const branchDir = path.join(repoDir, branch);
		if (fs.existsSync(branchDir)) return branchDir;
	}

	try {
		const entries = fs.readdirSync(repoDir, { withFileTypes: true });
		const dirs = entries.filter((e) => e.isDirectory()).map((e) => e.name);

		for (const preferred of ["main", "master"]) {
			if (dirs.includes(preferred)) {
				return path.join(repoDir, preferred);
			}
		}

		if (dirs.length > 0) {
			return path.join(repoDir, dirs[0]);
		}
	} catch {}

	return null;
}

export default function (pi: ExtensionAPI) {
	// Manual status check command
	pi.registerCommand("repo-daemon", {
		description: "Check repo-daemon status and list available repos",
		handler: async (args, ctx) => {
			const resp = await daemonRequest({ action: "ping" }, 2000);
			if (!resp?.ok) {
				ctx.ui.notify(
					`repo-daemon is not running.\nSocket: ${SOCKET_PATH}\nStart it on the host or check the service.`,
					"error",
				);
				return;
			}

			if (args.trim()) {
				// /repo-daemon owner/repo — list branches
				const parts = args.trim().split("/");
				if (parts.length === 2) {
					const listResp = await daemonRequest({
						action: "list",
						owner: parts[0],
						repo: parts[1],
					});
					if (listResp?.ok && listResp.branches) {
						ctx.ui.notify(
							`${args.trim()} branches:\n${listResp.branches.map((b: string) => `  ${b}`).join("\n") || "  (none cloned)"}`,
							"info",
						);
					} else {
						ctx.ui.notify(listResp?.error || "Failed to list", "error");
					}
				} else {
					ctx.ui.notify("Usage: /repo-daemon [owner/repo]", "error");
				}
			} else {
				ctx.ui.notify(
					`repo-daemon is running.\nSocket: ${SOCKET_PATH}`,
					"info",
				);
			}
		},
	});

	pi.registerTool({
		name: "resolve_repo",
		label: "Resolve Repo",
		description: [
			"Resolve a repository to a local filesystem path.",
			"Uses repo-daemon (for authenticated clones) or ~/code (locally available worktrees).",
			"Returns the path so you can read/grep/find files directly.",
		].join(" "),
		parameters: Type.Object({
			repo: Type.String({
				description:
					"Repository as owner/repo (e.g. 'nix-community/home-manager')",
			}),
			branch: Type.Optional(
				Type.String({
					description: "Branch to resolve (default: main/master)",
				}),
			),
		}),

		async execute(_toolCallId, params) {
			const parts = params.repo.split("/");
			if (parts.length !== 2) {
				return {
					content: [
						{
							type: "text" as const,
							text: `Invalid repo format: "${params.repo}". Use "owner/repo".`,
						},
					],
					details: undefined,
				};
			}

			const [owner, repo] = parts;
			let repoPath: string | null = null;
			let source = "unknown";

			// 1. Try repo-daemon
			const daemonResp = await daemonRequest({
				action: "ensure",
				owner,
				repo,
				branch: params.branch,
			});

			if (daemonResp?.ok && daemonResp.path) {
				repoPath = daemonResp.path;
				source = `daemon (${daemonResp.source || "cloned"})`;
			}

			// 2. Try local ~/code lookup
			if (!repoPath) {
				repoPath = findLocalRepo(owner, repo, params.branch);
				if (repoPath) source = "local";
			}

			// 3. Not available
			if (!repoPath) {
				const daemonStatus =
					daemonResp === null
						? "repo-daemon is not running"
						: `repo-daemon error: ${daemonResp.error || "unknown"}`;
				return {
					content: [
						{
							type: "text" as const,
							text: `Repository ${owner}/${repo} is not available.\n${daemonStatus}\nRun on the host: f -e ${owner}/${repo}/${params.branch || "main"}`,
						},
					],
					details: undefined,
				};
			}

			return {
				content: [
					{
						type: "text" as const,
						text: `Repository resolved (${source}):\n${repoPath}\n\nYou can now read, grep, and find files at this path.`,
					},
				],
				details: undefined,
			};
		},
	});
}
