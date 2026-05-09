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
    };

    agents = [
      ./agents/explorer.md
      ./agents/planner.md
      ./agents/reviewer.md
      ./agents/scout.md
      ./agents/worker.md
    ];

    extensions = [
      ./extensions/explore-repo.ts
      ./extensions/session-name.ts
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
