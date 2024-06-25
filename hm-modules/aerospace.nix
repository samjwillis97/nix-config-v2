{ config, lib, pkgs, ... }:
with lib;
let 
  cfg = config.modules.aerospace;
in
{

  options.modules.aerospace = {
    enable = mkEnableOption "an i3-like window manager for macOS";

    package = mkOption {
      type = types.package;
      default = pkgs.aerospace;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
