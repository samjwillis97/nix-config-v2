{
  config,
  pkgs,
  flake,
  ...
}:
{
  imports = [
    ../../../hm-modules/pi.nix
    ./repo-daemon.nix
  ];

  modules.pi = {
    enable = true;

    defaultProvider = "github-copilot";
    defaultModel = "claude-opus-4.6";

    extraSettings = {
      defaultThinkingLevel = "medium";
      hideThinkingBlock = false;

      packages = [
        "git:github.com/apmantza/pi-lens@v3.8.42"
      ];
    };

    rules = ./AGENTS.md;

    agents = [
      ./agents/brainstormer.md
      ./agents/explorer.md
      ./agents/planner.md
      ./agents/reviewer.md
      ./agents/scout.md
      ./agents/spec-reviewer.md
      ./agents/worker.md
    ];

    skills.local = [
      ./skills/brainstorming
      ./skills/creating-a-commit
      ./skills/dispatching-parallel-agents
      ./skills/executing-plans
      ./skills/git-workflow
      ./skills/planning
      ./skills/receiving-code-review
      ./skills/systematic-debugging
      ./skills/verification
      ./skills/writing-skills
    ];

    prompts = [
      ./prompts/brainstorm.md
      ./prompts/debug.md
      ./prompts/gc.md
      ./prompts/implement.md
      ./prompts/implement-and-review.md
      ./prompts/review.md
      ./prompts/scout-and-plan.md
    ];

    extensions = [
      ./extensions/anti-rationalization.ts
      # ./extensions/context-curator.ts  # disabled: redundant with AGENTS.md skill hints and natural tool use
      ./extensions/debug-assistant.ts
      ./extensions/explore-repo.ts
      ./extensions/plan-mode.ts
      ./extensions/review-pipeline.ts
      ./extensions/session-dashboard.ts
      ./extensions/session-name.ts
      ./extensions/verification-tracker.ts
      ./extensions/workflow-gate.ts
      ./extensions/auto-orchestrator.ts
    ];

    extensionDirs = [
      {
        name = "subagent";
        src = ./extensions/subagent;
      }
    ];

    repoDaemon.enable = true;
    repoDaemon.extraPackages = with pkgs; [ f ];

    sandbox.enable = true;
    sandbox.readOnlyDirs = [
      "$HOME/code"
    ];
    sandbox.extraAllowedPackages = with pkgs; [
      gh
      f
      nix
      bun
      pnpm
      rsync
    ];

    sandbox.extraStateDirs = [
      "$HOME/.npm"
      "$HOME/.cache"
      "$HOME/.config/gh"
      "/nix/var/nix/daemon-socket"
    ];
  };
}
