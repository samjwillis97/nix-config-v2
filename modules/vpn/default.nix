{ config, lib, pkgs, ... }:
with lib;
let cfg = config.services.vpn;
in {
  imports = [ ../../secrets ];

  options.services.vpn = {
    enable = mkEnableOption "Enables VPN service";
  };

  config = mkIf cfg.enable {
    warnings = [
      "Module \"services.vpn\" is still under construction"
    ];

    networking.firewall = {
      allowedUDPPorts = [ 51820 ];
    };

    networking.wireguard.interfaces = {
      wg0 = {
        ips = [ "10.100.0.24" ];
        listenPort = 51820;

        privateKeyFile = config.age.secrets."wireguard_private-key".path;

        peers = [
          {
            publicKey = "KIm+13jfrrbXNPqYpd+WaWnCrgubWaSQnj8xn1Od8Fk=";
            allowedIPs = [ "0.0.0.0/0" ];
            endpoint = "138.199.33.225:51820";
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };
}
