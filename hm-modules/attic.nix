{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.attic;
in
{

  options.modules.attic = {
    enable = mkEnableOption "attic cache";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ attic-client ];
    #
    # home.file."${config.xdg.configHome}/attic/config.toml" = config.age.secrets."attic-config".path;
  };
}
