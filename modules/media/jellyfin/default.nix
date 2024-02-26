{ config, lib, ... }:
with lib;
let cfg = config.modules.media.jellyfin;
in {
  options.modules.media.jellyfin = {
    enable = mkEnableOption "Enables Jellyfin service";
  };

  config = mkIf cfg.enable {
    warnings =
      [ ''Module "services.media.jellyfin" is still under construction'' ];

    services.jellyfin.enable = true;
  };
}
