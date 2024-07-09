{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.networking.vpn;
in
{
  imports = [ ../../../secrets/system.nix ];

  options.modules.networking.vpn = {
    enable = mkEnableOption "Enables VPN service";
  };

  config = mkIf cfg.enable {
    warnings = [ ''Module "services.vpn" is still under construction'' ];

    # Apparently don't need this post 21.05
    # boot.extraModulePackages = [config.boot.kernelPackages.wireguard];

    programs.mtr.enable = true;

    # See: https://alberand.com/nixos-wireguard-vpn.html
    networking.wg-quick.interfaces = {
      wg0 = {
        address = [
          "10.2.0.2/32"
        ];
        listenPort = 51820;
        privateKeyFile = config.age.secrets."wireguard_private-key".path;
        peers = [
          {
            publicKey = "8kyi2e0ziUqhs+ooJYYI0yaVhv/bneUC1fhV5X2q/SE=";
            allowedIPs = [ "0.0.0.0/0" ];
            endpoint = "185.159.157.192:51820";
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };
}
