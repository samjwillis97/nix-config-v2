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
    enable = mkEnableOption "Enables VPN service - specifically for ProtonVPN currently";

    address = mkOption {
      type = types.listOf types.str;
    };

    dns = mkOption {
      type = types.listOf types.str;
    };

    privateKeyFile = mkOption {
      type = types.str;
    };

    peer = {
      endpoint = mkOption {
        type = types.str;
      };

      publicKey = mkOption {
        type = types.str;
      };

      allowedIPs = mkOption {
        type = types.listOf types.str;
        default = [ "0.0.0.0/0"];
      };
    };

    portForwarding = {
      enable = mkEnableOption "Enable Port Forwarding";

      gateway = mkOption {
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ libnatpmp ];

    programs.mtr.enable = true;

    # See: https://alberand.com/nixos-wireguard-vpn.html
    networking.wg-quick.interfaces = {
      wg0 = {
        address = cfg.address;
        # listenPort = 51820; # Might not be needed?
        dns = cfg.dns;
        privateKeyFile = cfg.privateKeyFile;
        peers = [
          {
            publicKey = cfg.peer.publicKey;
            allowedIPs = cfg.peer.allowedIPs;
            endpoint = cfg.peer.endpoint;
            persistentKeepalive = 25;
          }
        ];
      };
    };

    # https://protonvpn.com/support/port-forwarding-manual-setup
    systemd.services.wg-port-forward = mkIf cfg.portForwarding.enable {
      description = "enable port forwarding for wg VPN";

      after = [
        "network-pre.target"
        "wg-quick-wg0.service"
      ];
      wants = [
        "network-pre.target"
        "wg-quick-wg0.service"
      ];

      wantedBy = [ "multi-user.target" ];

      script = ''
        # Create UDP port mapping
        ${pkgs.libnatpmp}/bin/natpmpc -a 1 0 udp 60 -g ${cfg.portForwarding.gateway}

        # Create TCP port mapping
        ${pkgs.libnatpmp}/bin/natpmpc -a 1 0 tcp 60 -g ${cfg.portForwarding.gateway}

        while true ; do date ; ${pkgs.libnatpmp}/bin/natpmpc -a 1 0 udp 60 -g ${cfg.portForwarding.gateway} && ${pkgs.libnatpmp}/bin/natpmpc -a 1 0 tcp 60 -g ${cfg.portForwarding.gateway} || { echo -e "ERROR with natpmpc command \a" ; break ; } ; sleep 45 ; done
      '';
    };
  };
}
