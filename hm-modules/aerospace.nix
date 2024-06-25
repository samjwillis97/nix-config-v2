{ config, lib, pkgs, ... }:
with lib;
let 
  cfg = config.modules.aerospace;
  tomlFormat = pkgs.formats.toml { };
in
{

  options.modules.aerospace = {
    enable = mkEnableOption "an i3-like window manager for macOS";

    package = mkOption {
      type = types.package;
      default = pkgs.aerospace;
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "aerospace/aerospace.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "config" cfg.settings;
      };
    };
  };
}
