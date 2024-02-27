{ config, lib, ... }:
with lib;
let
  cfg = config.hm-modules.desktop.wallpaper;
  user = config.meta.username; # Maybe super is useful for this
in {
  options.hm-modules.desktop.wallpaper = {
    path = mkOption {
      default = null;
      type = types.nullOr types.path;
    };
  };

  config = mkIf (cfg.path != null) {
    home-manager.users.${user}.theme.wallpaper.path = cfg.path;
  };
}
