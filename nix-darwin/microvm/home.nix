{ config, lib, ... }:
{
  options.workMicrovm.extraZshInit = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Extra shell init lines for work-mbp microvm guests.";
  };

  config = {
    home.username = "sam";
    home.homeDirectory = "/home/sam";
    home.stateVersion = "24.05";

    programs.zsh = {
      enable = true;
      initContent = ''
        export OPENCODE_CONFIG_DIR=/home/sam/opencode-microvm
        export CLAUDE_CONFIG_DIR=/home/sam/opencode-microvm
        cd /workspace
        ${config.workMicrovm.extraZshInit}
      '';
    };

    programs.home-manager.enable = true;
  };
}
