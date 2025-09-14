export const NotificationPlugin = async ({
  project,
  client,
  $,
  directory,
  worktree,
}) => {
  return {
    event: async ({ event }) => {
      // Send notification on session completion
      if (event.type === "session.idle") {
        await $`terminal-notifier -title 'Opencode session waiting...' -message 'Session: ${directory}'`;
      }
    },
  };
};
