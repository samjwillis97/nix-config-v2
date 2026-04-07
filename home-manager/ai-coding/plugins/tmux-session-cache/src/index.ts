import type { Plugin } from "@opencode-ai/plugin";
import {
  writeFileSync,
  readFileSync,
  mkdirSync,
  existsSync,
  renameSync,
} from "fs";
import { join } from "path";
import { createHash } from "crypto";
import { homedir } from "os";

const CACHE_DIR = join(homedir(), ".cache", "opencode", "tmux-cache");
const NOTIFICATION_FILE = join(
  homedir(),
  ".cache",
  "opencode",
  "tmux-notifications.json",
);
const MAX_QUEUE_SIZE = 50;
const UPDATE_DEBOUNCE_MS = 500;

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

interface NotificationEntry {
  worktree: string;
  event: "complete" | "error" | "permission" | "question" | "plan_exit";
  sessionId: string;
  title: string;
  timestamp: number;
}

function hashWorktree(worktree: string): string {
  return createHash("sha256").update(worktree).digest("hex");
}

function ensureCacheDir(): void {
  mkdirSync(CACHE_DIR, { recursive: true });
}

function ensureNotificationDir(): void {
  mkdirSync(join(homedir(), ".cache", "opencode"), { recursive: true });
}

function writeCache(worktree: string, data: SessionData): void {
  ensureCacheDir();
  const filePath = join(CACHE_DIR, `${hashWorktree(worktree)}.json`);
  const tmpPath = `${filePath}.tmp`;
  writeFileSync(tmpPath, JSON.stringify(data, null, 2));
  renameSync(tmpPath, filePath);
}

function appendNotification(entry: NotificationEntry): void {
  ensureNotificationDir();

  let queue: NotificationEntry[] = [];
  if (existsSync(NOTIFICATION_FILE)) {
    try {
      queue = JSON.parse(readFileSync(NOTIFICATION_FILE, "utf-8"));
      if (!Array.isArray(queue)) queue = [];
    } catch {
      queue = [];
    }
  }

  queue.push(entry);

  // Prune to last MAX_QUEUE_SIZE entries
  if (queue.length > MAX_QUEUE_SIZE) {
    queue = queue.slice(-MAX_QUEUE_SIZE);
  }

  const tmpPath = `${NOTIFICATION_FILE}.tmp`;
  writeFileSync(tmpPath, JSON.stringify(queue, null, 2));
  renameSync(tmpPath, NOTIFICATION_FILE);
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
  let updateTimer: ReturnType<typeof setTimeout> | null = null;

  async function handleTerminalEvent(
    sessionID: string,
    notifEvent: NotificationEntry["event"],
  ): Promise<void> {
    const data = await fetchSessionData(client, sessionID, worktree);
    writeCache(worktree, data);
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
                const data = await fetchSessionData(
                  client,
                  sessionID,
                  worktree,
                );
                writeCache(worktree, data);
              } catch (err) {
                console.error(
                  "[tmux-session-cache] debounced update error:",
                  err,
                );
              }
            }, UPDATE_DEBOUNCE_MS);
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
          appendNotification({
            worktree,
            event: "question",
            sessionId: sessionID,
            title: "",
            timestamp: Date.now(),
          });
        }

        if (input.tool === "plan_exit") {
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
