{
  config,
  pkgs,
  flake,
  ...
}:
let
  rpivAskUser = import ./packages/rpiv-ask-user-question.nix { inherit pkgs; };
  workEnabled = config.modules.darwin.work;
in
{
  imports = [
    ../../../hm-modules/pi.nix
    ./repo-daemon.nix
  ];

  modules.pi = {
    enable = true;

    defaultProvider = if workEnabled then "github-copilot" else "openai-codex";
    defaultModel = "gpt-5.6-terra";

    extraSettings = {
      defaultThinkingLevel = "medium";

      subagents.agentOverrides = {
        worker = {
          model = "gpt-5.6-luna";
          thinking = "xhigh";
          timeoutMs = 1200000;
        };

        scout = {
          model = "gpt-5.6-luna";
          thinking = "low";
          timeoutMs = 1200000;
        };

        reviewer = {
          model = "gpt-5.6-terra";
          thinking = "high";
          timeoutMs = 1200000;
        };
      };

      hideThinkingBlock = false;

      theme = "stylix";

      packages = [
        "git:github.com/apmantza/pi-lens@v3.8.70"
        "git:github.com/MasuRii/pi-tool-display@v0.5.0"
        "git:github.com/nicobailon/pi-subagents@v0.35.1"
      ];
    };

    nixPackages = [ rpivAskUser ];

    rules = ./AGENTS.md;

    agents = [
      ./agents/scout.md
      ./agents/worker.md
      ./agents/reviewer.md
    ];

    skills.local = [
      ./skills/creating-a-commit
      ./skills/git-workflow
    ];

    prompts = [
      ./prompts/gc.md
    ];

    extensions = [
      ./extensions/explore-repo.ts
      ./extensions/session-name.ts
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

        "openai.com" = "tunnel";
        "chatgpt.com" = "tunnel";

        "ui.shadcn.com" = [
          "GET"
          "HEAD"
        ];

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
        # JIRA_API_TOKEN = "$(cat \"${config.age.secrets.jira-token.path}\")";
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
