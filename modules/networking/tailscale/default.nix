{ config, lib, ... }:
with lib;
let cfg = config.modules.networking.tailscale;
in {
  options.modules.networking.tailscale = {
    enable = mkEnableOption "Enables tailscale";

    allowExitNode = mkEnableOption "Allows using node as exit node";

    advertiseRoutes = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = ''["10.0.0.0/24"]'';
      description = "List of routes to advertise";
    };
  };

  config = mkIf cfg.enable {
    warnings  =
      [ ''Module "services.tailscale" is still under construction'' ];
  };
}
