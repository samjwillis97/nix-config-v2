#!/usr/bin/env node
/**
 * repo-daemon — Host-side service that clones repos on behalf of sandboxed agents.
 *
 * Listens on a Unix socket and handles clone/ensure requests using `f`.
 * The sandboxed agent can request repos without needing any credentials.
 *
 * Protocol: newline-delimited JSON over Unix socket.
 *
 * Request:
 *   {"action": "ensure", "owner": "nix-community", "repo": "home-manager", "branch": "master"}
 *
 * Response:
 *   {"ok": true, "path": "/Users/sam/code/github.com/nix-community/home-manager/master"}
 *   {"ok": false, "error": "clone failed: ..."}
 *
 * Additional actions:
 *   {"action": "list", "owner": "nix-community", "repo": "home-manager"}
 *     → {"ok": true, "branches": ["main", "master", "release-24.05"]}
 *
 *   {"action": "ping"}
 *     → {"ok": true}
 */

const net = require("node:net");
const fs = require("node:fs");
const path = require("node:path");
const { execFile } = require("node:child_process");

function execFileAsync(command, args, options) {
	return new Promise((resolve, reject) => {
		execFile(command, args, options, (error, stdout, stderr) => {
			if (error) {
				error.stdout = stdout;
				error.stderr = stderr;
				reject(error);
			} else {
				resolve({ stdout, stderr });
			}
		});
	});
}

const SOCKET_PATH =
	process.env.REPO_DAEMON_SOCKET ||
	path.join(process.env.HOME, ".pi", "agent", "repo-daemon.sock");

const CODE_ROOT = path.join(process.env.HOME, "code");
const GIT_DOMAIN = "github.com";

// Find f binary
function findF() {
	// Check env override first
	if (process.env.F_BIN && fs.existsSync(process.env.F_BIN)) {
		return process.env.F_BIN;
	}

	// Search PATH directly (no shell utilities needed)
	const pathDirs = (process.env.PATH || "").split(":");
	for (const dir of pathDirs) {
		const candidate = path.join(dir, "f");
		try {
			fs.accessSync(candidate, fs.constants.X_OK);
			return candidate;
		} catch {}
	}

	// Search common nix locations
	const homeDir = process.env.HOME || "";
	const candidates = [
		path.join(homeDir, ".nix-profile", "bin", "f"),
		path.join(homeDir, ".local", "state", "nix", "profiles", "home-manager", "bin", "f"),
	];

	for (const candidate of candidates) {
		if (fs.existsSync(candidate)) return candidate;
	}

	return null;
}

const F_BIN_CACHE = { value: undefined, checked: false };

function getF() {
	if (!F_BIN_CACHE.checked) {
		F_BIN_CACHE.value = findF();
		F_BIN_CACHE.checked = true;
	}
	// Retry on each request if not found
	if (!F_BIN_CACHE.value) {
		F_BIN_CACHE.value = findF();
	}
	return F_BIN_CACHE.value;
}

// Find git binary on PATH (falls back to bare "git")
function findGit() {
	const pathDirs = (process.env.PATH || "").split(":");
	for (const dir of pathDirs) {
		const candidate = path.join(dir, "git");
		try {
			fs.accessSync(candidate, fs.constants.X_OK);
			return candidate;
		} catch {}
	}
	return "git";
}

const GIT_BIN_CACHE = { value: undefined };

function getGit() {
	if (GIT_BIN_CACHE.value === undefined) {
		GIT_BIN_CACHE.value = findGit();
	}
	return GIT_BIN_CACHE.value;
}

// Best-effort: fetch and fast-forward an existing worktree so explorations
// stay current. Never rewrites local work — skips if the worktree is dirty,
// has no upstream, or has diverged from its upstream. Any failure is
// swallowed and reported via the returned status string.
async function updateWorktree(worktreeDir) {
	const git = getGit();
	const run = (args) =>
		execFileAsync(git, ["-C", worktreeDir, ...args], {
			encoding: "utf-8",
			timeout: 60000,
		});

	try {
		// Must be inside a work tree
		await run(["rev-parse", "--is-inside-work-tree"]);

		// Skip if there are uncommitted changes
		const { stdout: status } = await run(["status", "--porcelain"]);
		if (status.trim() !== "") {
			return "skipped-dirty";
		}

		// Must have an upstream to update from
		let upstream;
		try {
			const { stdout } = await run([
				"rev-parse",
				"--abbrev-ref",
				"--symbolic-full-name",
				"@{u}",
			]);
			upstream = stdout.trim();
		} catch {
			return "skipped-no-upstream";
		}
		if (!upstream) {
			return "skipped-no-upstream";
		}

		// Refresh remote refs
		await run(["fetch", "--quiet"]);

		// Compare local HEAD against upstream: "<behind>\t<ahead>"
		const { stdout: counts } = await run([
			"rev-list",
			"--left-right",
			"--count",
			"@{u}...HEAD",
		]);
		const [behind, ahead] = counts
			.trim()
			.split(/\s+/)
			.map((n) => parseInt(n, 10) || 0);

		if (ahead > 0) {
			// Local commits not on upstream — don't touch (would not be a ff)
			return behind > 0 ? "skipped-diverged" : "skipped-ahead";
		}
		if (behind === 0) {
			return "up-to-date";
		}

		// Clean and strictly behind — safe to fast-forward
		await run(["merge", "--ff-only", "--quiet", "@{u}"]);
		return "fast-forwarded";
	} catch {
		return "skipped-error";
	}
}

async function ensureRepo(owner, repo, branch) {
	const repoDir = path.join(CODE_ROOT, GIT_DOMAIN, owner, repo);

	// Check if the branch worktree already exists
	if (branch) {
		const branchDir = path.join(repoDir, branch);
		if (fs.existsSync(branchDir)) {
			const update = await updateWorktree(branchDir);
			return { ok: true, path: branchDir, source: "existing", update };
		}
	} else {
		// No branch specified — find any existing worktree
		if (fs.existsSync(repoDir)) {
			try {
				const entries = fs.readdirSync(repoDir, { withFileTypes: true });
				const dirs = entries.filter((e) => e.isDirectory()).map((e) => e.name);
				for (const preferred of ["main", "master"]) {
					if (dirs.includes(preferred)) {
						const wt = path.join(repoDir, preferred);
						const update = await updateWorktree(wt);
						return { ok: true, path: wt, source: "existing", update };
					}
				}
				if (dirs.length > 0) {
					const wt = path.join(repoDir, dirs[0]);
					const update = await updateWorktree(wt);
					return { ok: true, path: wt, source: "existing", update };
				}
			} catch {}
		}
	}

	// Need to clone/checkout — use f
	const fBin = getF();
	if (!fBin) {
		return { ok: false, error: "f binary not found on host" };
	}

	const target = branch
		? `${owner}/${repo}/${branch}`
		: `${owner}/${repo}/main`;

	try {
		const { stdout: result } = await execFileAsync(fBin, ["-e", target], {
			encoding: "utf-8",
			timeout: 120000,
		});

		const resultPath = result.trim();
		if (resultPath && fs.existsSync(resultPath)) {
			return { ok: true, path: resultPath, source: "cloned" };
		}

		// f might not print the path on -e in all cases, construct it
		const expectedPath = path.join(
			repoDir,
			branch || "main",
		);
		if (fs.existsSync(expectedPath)) {
			return { ok: true, path: expectedPath, source: "cloned" };
		}

		// Try master if main failed
		if (!branch) {
			const masterPath = path.join(repoDir, "master");
			if (fs.existsSync(masterPath)) {
				return { ok: true, path: masterPath, source: "cloned" };
			}
		}

		return { ok: false, error: `f completed but repo not found at expected path` };
	} catch (err) {
		// execFile error includes stderr noise (like 'which: no tmux')
		// Extract just the meaningful part
		const stderr = err.stderr?.toString().trim() || "";
		const stdout = err.stdout?.toString().trim() || "";
		const meaningful = stderr
			.split("\n")
			.filter(line => !line.includes("which: no") && line.trim())
			.join("\n");
		const detail = meaningful || stdout || `exit code ${err.status}`;
		return { ok: false, error: `f failed: ${detail}` };
	}
}

function listBranches(owner, repo) {
	const repoDir = path.join(CODE_ROOT, GIT_DOMAIN, owner, repo);

	if (!fs.existsSync(repoDir)) {
		return { ok: true, branches: [] };
	}

	try {
		const entries = fs.readdirSync(repoDir, { withFileTypes: true });
		const branches = entries
			.filter((e) => e.isDirectory())
			.map((e) => e.name);
		return { ok: true, branches };
	} catch (err) {
		return { ok: false, error: `Failed to list: ${err.message}` };
	}
}

async function handleRequest(data) {
	try {
		const req = JSON.parse(data);

		switch (req.action) {
			case "ping":
				return { ok: true };

			case "ensure":
				if (!req.owner || !req.repo) {
					return { ok: false, error: "Missing owner or repo" };
				}
				return ensureRepo(req.owner, req.repo, req.branch);

			case "list":
				if (!req.owner || !req.repo) {
					return { ok: false, error: "Missing owner or repo" };
				}
				return listBranches(req.owner, req.repo);

			default:
				return { ok: false, error: `Unknown action: ${req.action}` };
		}
	} catch (err) {
		return { ok: false, error: `Invalid request: ${err.message}` };
	}
}

// Clean up stale socket
if (fs.existsSync(SOCKET_PATH)) {
	try {
		// Check if another instance is running
		const client = net.createConnection(SOCKET_PATH);
		client.on("connect", () => {
			console.error(`repo-daemon already running on ${SOCKET_PATH}`);
			client.destroy();
			process.exit(1);
		});
		client.on("error", () => {
			// Stale socket, remove it
			fs.unlinkSync(SOCKET_PATH);
			startServer();
		});
	} catch {
		fs.unlinkSync(SOCKET_PATH);
		startServer();
	}
} else {
	startServer();
}

function startServer() {
	// Ensure socket directory exists
	fs.mkdirSync(path.dirname(SOCKET_PATH), { recursive: true });

	const server = net.createServer((conn) => {
		let buffer = "";

		conn.on("data", (chunk) => {
			buffer += chunk.toString();

			// Process complete lines
			let newlineIdx;
			while ((newlineIdx = buffer.indexOf("\n")) !== -1) {
				const line = buffer.slice(0, newlineIdx).trim();
				buffer = buffer.slice(newlineIdx + 1);

				if (line) {
					handleRequest(line).then(response => {
						conn.write(JSON.stringify(response) + "\n");
					});
				}
			}
		});

		conn.on("error", () => {});
	});

	server.listen(SOCKET_PATH, () => {
		// Set permissions so the sandbox user can access it
		fs.chmodSync(SOCKET_PATH, 0o770);
		console.log(`repo-daemon listening on ${SOCKET_PATH}`);
		console.log(`PATH: ${process.env.PATH}`);
		const fStatus = getF();
		if (fStatus) {
			console.log(`Using f at: ${fStatus}`);
		} else {
			console.log("WARNING: f not found — clone requests will fail");
		}
		console.log(`Code root: ${CODE_ROOT}`);
	});

	server.on("error", (err) => {
		console.error(`Failed to start: ${err.message}`);
		process.exit(1);
	});

	// Cleanup on exit
	function cleanup() {
		try {
			fs.unlinkSync(SOCKET_PATH);
		} catch {}
		process.exit(0);
	}

	process.on("SIGINT", cleanup);
	process.on("SIGTERM", cleanup);
	process.on("SIGHUP", cleanup);
}
