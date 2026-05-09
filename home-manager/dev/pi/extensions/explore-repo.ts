/**
 * Explore Repo Tool - Discover and explore external repositories
 *
 * Handles finding repos via:
 *   1. repo-daemon Unix socket (asks host to clone with full auth)
 *   2. Local ~/code lookup (f's managed worktrees, read-only)
 *   3. Shallow HTTPS clone to /tmp (public repos only, no auth needed)
 *
 * Then delegates to the explorer subagent with the correct cwd.
 *
 * Usage by the LLM:
 *   explore_repo({ repo: "nix-community/home-manager", task: "how do activation scripts work?" })
 *   explore_repo({ repo: "samjwillis97/some-private-repo", branch: "feature-x", task: "..." })
 */

import * as fs from "node:fs";
import * as net from "node:net";
import * as os from "node:os";
import * as path from "node:path";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
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
): Promise<{ ok: boolean; path?: string; source?: string; error?: string; branches?: string[] } | null> {
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
function findLocalRepo(owner: string, repo: string, branch?: string): string | null {
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
  } catch { }

  return null;
}

export default function(pi: ExtensionAPI) {
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
          const listResp = await daemonRequest({ action: "list", owner: parts[0], repo: parts[1] });
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
        ctx.ui.notify(`repo-daemon is running.\nSocket: ${SOCKET_PATH}`, "success");
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
        description: "Repository as owner/repo (e.g. 'nix-community/home-manager')",
      }),
      branch: Type.Optional(
        Type.String({ description: "Branch to resolve (default: main/master)" }),
      ),
    }),

    async execute(_toolCallId, params) {
      const parts = params.repo.split("/");
      if (parts.length !== 2) {
        return {
          content: [{ type: "text", text: `Invalid repo format: "${params.repo}". Use "owner/repo".` }],
          isError: true,
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
        const daemonStatus = daemonResp === null
          ? "repo-daemon is not running"
          : `repo-daemon error: ${daemonResp.error || "unknown"}`;
        return {
          content: [{
            type: "text",
            text: `Repository ${owner}/${repo} is not available.\n${daemonStatus}\nRun on the host: f -e ${owner}/${repo}/${params.branch || "main"}`,
          }],
          isError: true,
        };
      }

      return {
        content: [{
          type: "text",
          text: `Repository resolved (${source}):\n${repoPath}\n\nYou can now read, grep, and find files at this path.`,
        }],
      };
    },
  });

  pi.registerTool({
    name: "explore_repo",
    description: [
      "Explore an external repository. Resolves repos via: (1) repo-daemon for authenticated clones,",
      "(2) ~/code for locally available worktrees, (3) HTTPS shallow clone for public repos.",
      "Delegates investigation to an isolated explorer subagent.",
    ].join(" "),
    parameters: Type.Object({
      repo: Type.String({
        description: "Repository as owner/repo (e.g. 'nix-community/home-manager')",
      }),
      branch: Type.Optional(
        Type.String({ description: "Branch to explore (default: main/master)" }),
      ),
      task: Type.String({
        description: "What to investigate in the repository",
      }),
    }),

    async execute(_toolCallId, params, signal, onUpdate, ctx) {
      const parts = params.repo.split("/");
      if (parts.length !== 2) {
        return {
          content: [{ type: "text", text: `Invalid repo format: "${params.repo}". Use "owner/repo".` }],
          isError: true,
        };
      }

      const [owner, repo] = parts;
      let repoPath: string | null = null;
      let source = "unknown";

      // 1. Try repo-daemon (host-side clone with full auth)
      if (onUpdate) {
        onUpdate({ content: [{ type: "text", text: `Resolving ${owner}/${repo}...` }] });
      }

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

      // 3. Repo not available — report clearly
      if (!repoPath) {
        const daemonStatus = daemonResp === null
          ? "repo-daemon is not running — start it on the host for private repo access."
          : `repo-daemon could not resolve: ${daemonResp.error || "unknown error"}`;

        return {
          content: [
            {
              type: "text",
              text: [
                `Repository ${owner}/${repo} is not available.`,
                "",
                "Checked:",
                `  1. repo-daemon socket: ${daemonStatus}`,
                `  2. ~/code/${GIT_DOMAIN}/${owner}/${repo}: not found`,
                "",
                "To make this repo available:",
                `  • Start repo-daemon on the host (handles private repos via SSH)`,
                `  • Or run on the host: f -e ${owner}/${repo}/${params.branch || "main"}`,
              ].join("\n"),
            },
          ],
          isError: true,
        };
      }

      // 4. Spawn explorer subagent
      if (onUpdate) {
        onUpdate({ content: [{ type: "text", text: `Exploring ${owner}/${repo} (${source})...` }] });
      }

      const taskWithContext = [
        `Repository: ${owner}/${repo}`,
        `Source: ${source}`,
        `Path: ${repoPath}`,
        params.branch ? `Branch: ${params.branch}` : "",
        "",
        `Task: ${params.task}`,
      ]
        .filter(Boolean)
        .join("\n");

      const args: string[] = ["--mode", "json", "-p", "--no-session", "--tools", "read,grep,find,ls,bash"];

      if (ctx.model) {
        args.push("--model", `${ctx.model.provider}/${ctx.model.id}`);
      }

      const explorerAgent = path.join(os.homedir(), ".pi", "agent", "agents", "explorer.md");
      if (fs.existsSync(explorerAgent)) {
        args.push("--append-system-prompt", explorerAgent);
      }

      args.push(taskWithContext);

      const { spawn } = await import("node:child_process");

      const usage = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 };
      let finalOutput = "";
      let model: string | undefined;

      const exitCode = await new Promise<number>((resolve) => {
        const currentScript = process.argv[1];
        let command: string;
        let spawnArgs: string[];

        if (currentScript && fs.existsSync(currentScript)) {
          command = process.execPath;
          spawnArgs = [currentScript, ...args];
        } else {
          command = "pi";
          spawnArgs = args;
        }

        const proc = spawn(command, spawnArgs, {
          cwd: repoPath!,
          shell: false,
          stdio: ["ignore", "pipe", "pipe"],
        });

        let buffer = "";

        proc.stdout.on("data", (data: Buffer) => {
          buffer += data.toString();
          const lines = buffer.split("\n");
          buffer = lines.pop() || "";

          for (const line of lines) {
            if (!line.trim()) continue;
            try {
              const event = JSON.parse(line);
              if (event.type === "message_end" && event.message?.role === "assistant") {
                usage.turns++;
                const u = event.message.usage;
                if (u) {
                  usage.input += u.input || 0;
                  usage.output += u.output || 0;
                  usage.cacheRead += u.cacheRead || 0;
                  usage.cacheWrite += u.cacheWrite || 0;
                  usage.cost += u.cost?.total || 0;
                }
                if (!model && event.message.model) model = event.message.model;
                for (const part of event.message.content || []) {
                  if (part.type === "text") finalOutput = part.text;
                }
                if (onUpdate) {
                  onUpdate({ content: [{ type: "text", text: finalOutput || "(exploring...)" }] });
                }
              }
            } catch { }
          }
        });

        proc.stderr.on("data", () => { });
        proc.on("close", (code) => {
          if (buffer.trim()) {
            try {
              const event = JSON.parse(buffer);
              if (event.type === "message_end" && event.message?.role === "assistant") {
                for (const part of event.message.content || []) {
                  if (part.type === "text") finalOutput = part.text;
                }
              }
            } catch { }
          }
          resolve(code ?? 0);
        });
        proc.on("error", () => resolve(1));

        if (signal) {
          const kill = () => {
            proc.kill("SIGTERM");
            setTimeout(() => { if (!proc.killed) proc.kill("SIGKILL"); }, 5000);
          };
          if (signal.aborted) kill();
          else signal.addEventListener("abort", kill, { once: true });
        }
      });

      if (exitCode !== 0 && !finalOutput) {
        return {
          content: [{ type: "text", text: `Explorer failed (exit ${exitCode})` }],
          isError: true,
        };
      }

      return {
        content: [{ type: "text", text: finalOutput || "(no output)" }],
        details: { repo: params.repo, branch: params.branch, source, repoPath, usage, model },
      };
    },
  });
}
