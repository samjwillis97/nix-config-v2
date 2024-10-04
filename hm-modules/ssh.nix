{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.ssh;
in
{
  options.modules.ssh = {
    enable = mkEnableOption "Enable SSH";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      addKeysToAgent = "yes";
    };
  };
}
