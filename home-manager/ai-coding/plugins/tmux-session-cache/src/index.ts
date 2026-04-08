import type { Plugin } from "@opencode-ai/plugin";
import {
  writeFileSync,
  readFileSync,
  mkdirSync,
  existsSync,
  renameSync,
  unlinkSync,
  readdirSync,
  statSync,
} from "fs";
import { join } from "path";
import { homedir } from "os";

const CACHE_BASE = join(homedir(), ".cache", "opencode", "tmux-cache");
const SESSIONS_DIR = join(CACHE_BASE, "sessions");
const PIDS_DIR = join(CACHE_BASE, "pids");
const NOTIFICATION_FILE = join(
  homedir(),
  ".cache",
  "opencode",
  "tmux-notifications.json",
);
const MAX_QUEUE_SIZE = 50;
const UPDATE_DEBOUNCE_MS = 500;
const MAX_NOTIFICATION_AGE_MS = 15 * 60 * 1000; // 15 minutes
const MAX_SESSION_CACHE_AGE_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

interface SessionData {
  worktree: string;
  sessionId: string;
  title: string;
  model: string;
  provider: string;
  tokensIn: number;
  tokensOut: number;
  cost: number;
  additions: number;
  deletions: number;
  files: number;
  updatedAt: number;
}

interface PidMapping {
  pid: number;
  ppid: number;
  worktree: string;
  currentSessionId: string;
}

interface NotificationEntry {
  worktree: string;
  event: "complete" | "error" | "permission" | "question" | "plan_exit";
  sessionId: string;
  title: string;
  timestamp: number;
}

function ensureDir(dir: string): void {
  mkdirSync(dir, { recursive: true });
}

function atomicWrite(filePath: string, data: string): void {
  const tmpPath = `${filePath}.${process.pid}.${Date.now()}.tmp`;
  writeFileSync(tmpPath, data);
  renameSync(tmpPath, filePath);
}

function writeSessionCache(sessionId: string, data: SessionData): void {
  ensureDir(SESSIONS_DIR);
  atomicWrite(
    join(SESSIONS_DIR, `${sessionId}.json`),
    JSON.stringify(data, null, 2),
  );
}

function writePidMapping(mapping: PidMapping): void {
  ensureDir(PIDS_DIR);
  atomicWrite(
    join(PIDS_DIR, `${mapping.ppid}.json`),
    JSON.stringify(mapping, null, 2),
  );
}

function cleanupPidFile(ppid: number): void {
  try {
    const filePath = join(PIDS_DIR, `${ppid}.json`);
    if (existsSync(filePath)) {
      unlinkSync(filePath);
    }
  } catch {
    // Best effort cleanup
  }
}

function pruneStalePidFiles(): void {
  try {
    if (!existsSync(PIDS_DIR)) return;
    const files = readdirSync(PIDS_DIR);
    for (const file of files) {
      if (!file.endsWith(".json")) continue;
      const ppid = parseInt(file.replace(".json", ""), 10);
      if (isNaN(ppid)) continue;
      try {
        // Check if the process is still alive
        process.kill(ppid, 0);
      } catch {
        // Process is dead — remove stale PID file
        try {
          unlinkSync(join(PIDS_DIR, file));
        } catch {
          // Best effort
        }
      }
    }
  } catch {
    // Best effort cleanup
  }
}

function pruneStaleSessionFiles(): void {
  try {
    if (!existsSync(SESSIONS_DIR)) return;
    const now = Date.now();
    const files = readdirSync(SESSIONS_DIR);
    for (const file of files) {
      if (!file.endsWith(".json")) continue;
      try {
        const filePath = join(SESSIONS_DIR, file);
        const stat = statSync(filePath);
        if (now - stat.mtimeMs > MAX_SESSION_CACHE_AGE_MS) {
          unlinkSync(filePath);
        }
      } catch {
        // Best effort
      }
    }
  } catch {
    // Best effort cleanup
  }
}

function appendNotification(entry: NotificationEntry): void {
  ensureDir(join(homedir(), ".cache", "opencode"));

  let queue: NotificationEntry[] = [];
  if (existsSync(NOTIFICATION_FILE)) {
    try {
      queue = JSON.parse(readFileSync(NOTIFICATION_FILE, "utf-8"));
      if (!Array.isArray(queue)) queue = [];
    } catch {
      queue = [];
    }
  }

  // Prune entries older than 24 hours
  const ageCutoff = Date.now() - MAX_NOTIFICATION_AGE_MS;
  queue = queue.filter((e) => e.timestamp >= ageCutoff);

  queue.push(entry);

  // Prune to last MAX_QUEUE_SIZE entries
  if (queue.length > MAX_QUEUE_SIZE) {
    queue = queue.slice(-MAX_QUEUE_SIZE);
  }

  atomicWrite(NOTIFICATION_FILE, JSON.stringify(queue, null, 2));
}

async function fetchSessionData(
  client: any,
  sessionID: string,
  worktree: string,
): Promise<SessionData> {
  const sessionResponse = await client.session.get({
    path: { id: sessionID },
  });
  const session = sessionResponse.data;

  const messagesResponse = await client.session.messages({
    path: { id: sessionID },
  });
  const messages: any[] = messagesResponse.data ?? [];

  const title = session?.title ?? "";
  const additions = session?.summary?.additions ?? 0;
  const deletions = session?.summary?.deletions ?? 0;
  const files = session?.summary?.files ?? 0;
  const updatedAt = session?.time?.updated ?? Date.now();

  let tokensIn = 0;
  let tokensOut = 0;
  let cost = 0;
  let model = "";
  let provider = "";

  for (const msg of messages) {
    const info = msg?.info ?? msg;
    if (info?.role === "assistant") {
      tokensIn += info.tokens?.input ?? 0;
      tokensOut += info.tokens?.output ?? 0;
      cost += info.cost ?? 0;
    }
  }

  // Get model and provider from the last assistant message
  for (let i = messages.length - 1; i >= 0; i--) {
    const info = messages[i]?.info ?? messages[i];
    if (info?.role === "assistant") {
      model = info.modelID ?? "";
      provider = info.providerID ?? "";
      break;
    }
  }

  return {
    worktree,
    sessionId: sessionID,
    title,
    model,
    provider,
    tokensIn,
    tokensOut,
    cost,
    additions,
    deletions,
    files,
    updatedAt,
  };
}

function getSessionIDFromEvent(event: any): string | null {
  const props = (event as any)?.properties;
  if (!props) return null;

  // Direct sessionID (session.idle, session.error, permission.updated)
  if (typeof props.sessionID === "string" && props.sessionID) {
    return props.sessionID;
  }

  // Wrapped in info (session.updated, session.created, session.deleted)
  if (typeof props.info?.id === "string" && props.info.id) {
    return props.info.id;
  }

  return null;
}

export const TmuxSessionCachePlugin: Plugin = async ({ client, directory }) => {
  const worktree = directory;
  const myPpid = process.ppid;
  let currentSessionId = "";
  let updateTimer: ReturnType<typeof setTimeout> | null = null;

  function updatePidMapping(sessionId: string): void {
    currentSessionId = sessionId;
    writePidMapping({
      pid: process.pid,
      ppid: myPpid,
      worktree,
      currentSessionId: sessionId,
    });
  }

  // Prune stale PID files from dead processes before writing our own
  pruneStalePidFiles();

  // Prune old session cache files (>7 days)
  pruneStaleSessionFiles();

  // Write initial PID mapping (will be updated with sessionId on first event)
  writePidMapping({
    pid: process.pid,
    ppid: myPpid,
    worktree,
    currentSessionId: "",
  });

  // Cleanup PID file on exit
  const cleanup = () => cleanupPidFile(myPpid);
  process.on("exit", cleanup);
  process.on("SIGINT", () => {
    cleanup();
    process.exit(0);
  });
  process.on("SIGTERM", () => {
    cleanup();
    process.exit(0);
  });
  process.on("SIGHUP", () => {
    cleanup();
    process.exit(0);
  });

  async function handleTerminalEvent(
    sessionID: string,
    notifEvent: NotificationEntry["event"],
  ): Promise<void> {
    updatePidMapping(sessionID);
    const data = await fetchSessionData(client, sessionID, worktree);
    writeSessionCache(sessionID, data);
    appendNotification({
      worktree,
      event: notifEvent,
      sessionId: sessionID,
      title: data.title,
      timestamp: Date.now(),
    });
  }

  return {
    event: async ({ event }) => {
      try {
        const sessionID = getSessionIDFromEvent(event);
        if (!sessionID) return;

        switch ((event as any).type) {
          case "session.created": {
            // Pre-fill cache when a session is opened/switched to
            updatePidMapping(sessionID);
            try {
              const data = await fetchSessionData(
                client,
                sessionID,
                worktree,
              );
              writeSessionCache(sessionID, data);
            } catch (err) {
              // Session may be brand new with no data yet — that's fine
              console.error(
                "[tmux-session-cache] session.created cache prefill error:",
                err,
              );
            }
            break;
          }

          case "session.idle": {
            if (updateTimer) clearTimeout(updateTimer);
            await handleTerminalEvent(sessionID, "complete");
            break;
          }

          case "session.error": {
            if (updateTimer) clearTimeout(updateTimer);
            await handleTerminalEvent(sessionID, "error");
            break;
          }

          case "permission.updated": {
            updatePidMapping(sessionID);
            appendNotification({
              worktree,
              event: "permission",
              sessionId: sessionID,
              title: "",
              timestamp: Date.now(),
            });
            break;
          }

          case "session.updated": {
            // Debounce: session.updated fires frequently during active work
            if (updateTimer) clearTimeout(updateTimer);
            updateTimer = setTimeout(async () => {
              try {
                updatePidMapping(sessionID);
                const data = await fetchSessionData(
                  client,
                  sessionID,
                  worktree,
                );
                writeSessionCache(sessionID, data);
              } catch (err) {
                console.error(
                  "[tmux-session-cache] debounced update error:",
                  err,
                );
              }
            }, UPDATE_DEBOUNCE_MS);
            break;
          }

          case "session.status": {
            // Session became busy/idle — update PID mapping to track current session
            updatePidMapping(sessionID);
            break;
          }
        }
      } catch (err) {
        console.error("[tmux-session-cache] event handler error:", err);
      }
    },

    "tool.execute.before": async (input, _output) => {
      try {
        const sessionID = input?.sessionID ?? "";

        if (input.tool === "question") {
          updatePidMapping(sessionID);
          appendNotification({
            worktree,
            event: "question",
            sessionId: sessionID,
            title: "",
            timestamp: Date.now(),
          });
        }

        if (input.tool === "plan_exit") {
          updatePidMapping(sessionID);
          appendNotification({
            worktree,
            event: "plan_exit",
            sessionId: sessionID,
            title: "",
            timestamp: Date.now(),
          });
        }
      } catch (err) {
        console.error(
          "[tmux-session-cache] tool.execute.before handler error:",
          err,
        );
      }
    },
  };
};

export default TmuxSessionCachePlugin;
