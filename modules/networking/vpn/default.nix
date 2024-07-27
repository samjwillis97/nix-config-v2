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
        # dns = cfg.dns; # This seems to fuck with DNS resolution of course.. might be necessary who knows
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

    networking.enableIPv6 = false;

#     networking.firewall = {
#       # enable = false;
#       allowedUDPPortRanges = [
#         {
#           from = 45000;
#           to = 65000;
#         }
#       ];
#       allowedTCPPortRanges = [
#         {
#           from = 45000;
#           to = 65000;
#         }
#       ];
#     };

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
        while true ; do date ; ${pkgs.libnatpmp}/bin/natpmpc -a 1 0 udp 60 -g ${cfg.portForwarding.gateway} && ${pkgs.libnatpmp}/bin/natpmpc -a 1 0 tcp 60 -g ${cfg.portForwarding.gateway} || { echo -e "ERROR with natpmpc command \a" ; break ; } ; sleep 45 ; done
        # So i think somewhere here I need to extract the port from above
        # And set it in deluge, and restart deluge if it is different
        # fuck moi

        # may not be possible, but the best way currently is to
        # find the service ExecStart,
        # in there find the core.conf being used
        # modify in place there
        # this kind of ruins the declarative nature of everything, but this port is random
        # so
        # the read only file system ruins this..
        # Looks like there is JSON RPC API I might be able to use to set the port
        # Not sure if this is even working though
      '';
    };
  };
}
