{ config, lib, ... }:
with lib;
let cfg = config.services.media.jellyfin;
in {
  options.services.media.jellyfin = {
    enable = mkEnableOption "Enables Jellyfin service";
  };

  config = mkIf cfg.enable {
    warnings = [
      "Module \"services.media.jellyfin\" is still under construction"
    ];

    services.jellyfin.enable = true;
  };
}
