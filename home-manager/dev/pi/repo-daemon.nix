# home-manager/dev/pi/repo-daemon.nix
#
# Home-manager module for the repo-daemon service.
# Runs a small Node.js daemon that listens on a Unix socket
# and clones repositories on behalf of sandboxed agents.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption mkIf types;
  cfg = config.modules.pi.repoDaemon;

  daemonScript = ./repo-daemon.js;
  socketPath = "${config.home.homeDirectory}/.pi/agent/repo-daemon.sock";
in
{
  options.modules.pi.repoDaemon = {
    enable = mkEnableOption "Pi repo-daemon for sandboxed repository access";

    nodePackage = mkOption {
      type = types.package;
      default = pkgs.nodejs;
      description = "Node.js package to run the daemon with.";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional packages available to the daemon (e.g. f, git).";
    };
  };

  config = mkIf cfg.enable {
    # macOS launchd service
    launchd.agents.repo-daemon = lib.mkIf pkgs.stdenv.isDarwin {
      enable = true;
      config = {
        Label = "com.pi.repo-daemon";
        ProgramArguments = [
          "${cfg.nodePackage}/bin/node"
          "${daemonScript}"
        ];
        EnvironmentVariables = {
          PATH = lib.makeBinPath ([ cfg.nodePackage pkgs.coreutils pkgs.findutils pkgs.which pkgs.gnugrep pkgs.openssh pkgs.tmux pkgs.git ] ++ cfg.extraPackages);
          HOME = config.home.homeDirectory;
          REPO_DAEMON_SOCKET = socketPath;
        };
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${config.home.homeDirectory}/.pi/agent/repo-daemon.log";
        StandardErrorPath = "${config.home.homeDirectory}/.pi/agent/repo-daemon.log";
      };
    };

    # Linux systemd user service
    systemd.user.services.repo-daemon = lib.mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "Pi repo-daemon for sandboxed repository access";
        After = [ "default.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${cfg.nodePackage}/bin/node ${daemonScript}";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = [
          "PATH=${lib.makeBinPath ([ cfg.nodePackage pkgs.coreutils pkgs.findutils pkgs.which pkgs.gnugrep pkgs.openssh pkgs.tmux pkgs.git ] ++ cfg.extraPackages)}"
          "REPO_DAEMON_SOCKET=${socketPath}"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
