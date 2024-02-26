{ config, lib, ... }:
with lib;
let cfg = config.services.media.jellyfin;
in {
  options.services.media.jellyfin = {
    enable = mkEnableOption "Enables Jellyfin service";
  };

  config = mkIf cfg.enable {
    services.jellyfin.enable = true;
  };
}
