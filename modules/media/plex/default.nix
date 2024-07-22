{ config, lib, ... }:
with lib;
let
  cfg = config.modules.media.plex;

  mediaUserEnabled = config.modules.system.users.media;
in
{
  options.modules.media.plex = {
    enable = mkEnableOption "Enables Plex service";
  };

  config = mkIf cfg.enable {
    services.plex = {
      enable = true;

      user = if mediaUserEnabled then "media" else "plex";
      group = if mediaUserEnabled then "media" else "plex";
    };
  };
}
