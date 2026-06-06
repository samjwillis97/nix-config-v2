{
  config,
  pkgs,
  flake,
  ...
}:
let
  rpivAskUser = import ./packages/rpiv-ask-user-question.nix { inherit pkgs; };
in
{
  imports = [
    ../../../hm-modules/pi.nix
    ./repo-daemon.nix
  ];

  modules.pi = {
    enable = true;

    defaultProvider = "github-copilot";
    defaultModel = "claude-opus-4.8";

    extraSettings = {
      defaultThinkingLevel = "medium";
      hideThinkingBlock = false;

      theme = "stylix";

      packages = [
        "git:github.com/apmantza/pi-lens@v3.8.42"
        "git:github.com/MasuRii/pi-tool-display@v0.3.6"
        "git:github.com/nicobailon/pi-subagents@v0.28.0"
        # Use the npm spec (not git): the npm tarball ships the prebuilt
        # `build/` dir, so Pi's package loader can resolve the extension
        # entrypoint declared in the package's `pi.extensions`
        # (`./build/adapters/pi/extension.js`). The git clone omits `build/`
        # (it is .gitignore'd / build-time only), so the Pi extension — and
        # thus the PreToolUse routing hook + session continuity — never load.
        # "npm:context-mode@1.0.162"
      ];
    };

    # NOTE: No manual `mcpServers."context-mode"` entry. The context-mode Pi
    # extension (loaded via the npm package's `pi.extensions`) bootstraps its
    # own MCP bridge: it spawns `server.bundle.mjs` and registers each ctx_*
    # tool through `pi.registerTool()`. Registering the MCP server here too
    # would double-register every ctx_* tool. The extension is the single
    # integration surface (tools + routing hook + session continuity).

    nixPackages = [ rpivAskUser ];

    rules = ./AGENTS.md;

    agents = [
      # ./agents/brainstormer.md
      # ./agents/explorer.md
      # ./agents/planner.md
      # ./agents/reviewer.md
      # ./agents/scout.md
      # ./agents/spec-reviewer.md
      # ./agents/worker.md
    ];

    skills.local = [
      # ./skills/brainstorming
      ./skills/creating-a-commit
      # ./skills/dispatching-parallel-agents
      # ./skills/executing-plans
      # ./skills/finishing-work
      ./skills/git-workflow
      # ./skills/planning
      # ./skills/receiving-code-review
      # ./skills/systematic-debugging
      # ./skills/testing-discipline
      # ./skills/verification
      # ./skills/writing-skills
    ];

    prompts = [
      # ./prompts/brainstorm.md
      # ./prompts/debug.md
      ./prompts/gc.md
      # ./prompts/implement.md
      # ./prompts/implement-and-review.md
      # ./prompts/review.md
      # ./prompts/scout-and-plan.md
    ];

    extensions = [
      # ./extensions/context-curator.ts  # disabled: redundant with AGENTS.md skill hints and natural tool use
      # ./extensions/debug-assistant.ts
      ./extensions/explore-repo.ts
      # ./extensions/plan-mode.ts
      # ./extensions/review-pipeline.ts
      # ./extensions/session-dashboard.ts
      ./extensions/session-name.ts
      # ./extensions/verification-tracker.ts
      # ./extensions/workflow-gate.ts
      # ./extensions/auto-orchestrator.ts
    ];

    extensionDirs = [
      # {
      #   name = "subagent";
      #   src = ./extensions/subagent;
      # }
    ];

    repoDaemon.enable = true;
    repoDaemon.extraPackages = with pkgs; [ f ];

    sandbox = {
      enable = true;

      restrictNetwork = true;

      allowedDomains = {
        # Copilot required domains (MITM-filtered)
        "githubcopilot.com" = "*";

        # GitHub API/web: tunnelled (raw TCP passthrough) so `gh` trusts the
        # real GitHub cert. gh is a Go binary and on macOS ignores the proxy's
        # CA bundle (SSL_CERT_FILE), so it cannot use the MITM path.
        "github.com" = "tunnel";
        "api.github.com" = "tunnel";

        # Domain required for user content
        "githubusercontent.com" = [
          "GET"
          "HEAD"
        ];
        "npmjs.org" = [
          "GET"
          "HEAD"
        ];
      };

      extraEnv = {
        # Bridge the keychain-stored gh token into the sandbox.
        # `gh auth token` runs on the host (keychain reachable) at launch;
        # the resulting token is injected as GITHUB_TOKEN. The token never
        # enters the nix store - only this command string does.
        GH_TOKEN = "$(${pkgs.gh}/bin/gh auth token)";

        # context-mode stores its SQLite session/content DBs under
        # ~/.config/<platform>/context-mode by default, which is NOT a
        # writable dir in this sandbox. Redirect storage to ~/.cache
        # (already an extraStateDir) so the MCP server can create its DBs.
        # CONTEXT_MODE_DIR = "$HOME/.cache/context-mode";
      };

      readOnlyDirs = [
        "$HOME/code"
      ];

      extraAllowedPackages = with pkgs; [
        gh
        f
        bun
        pnpm
        rsync
        # Put pi itself on PATH inside the sandbox so the pi-subagents
        # extension can re-spawn `pi` for subagents (otherwise the bare
        # `pi` command fails with `spawn pi ENOENT`).
        llm-agents.pi
      ];

      extraStateDirs = [
        "$HOME/.npm"
        "$HOME/.cache"
        "$HOME/.config/gh"
        "$HOME/.config/git"
        "$HOME/.ssh"
        "/nix/var/nix/daemon-socket"
      ];
    };
  };
}
