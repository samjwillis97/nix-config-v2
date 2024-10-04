{ config, ... }:
{
  imports = [
    ../../../secrets/wireguard/system.nix
    ../../../modules/networking/vpn
    ../../../modules/media/deluge
    ../../../modules/system/users
    ../../../modules/monitoring/exporters
    ../../../modules/monitoring/promtail
  ];

  networking.hostName = "iso-grabber";

  modules.monitoring = {
    promtail = {
      enable = true;
      lokiUrl = "http://insights:3100";
    };

    exporters.system.enable = true;
  };

  modules.system.users.media = true;

  modules = {
    networking.vpn = {
      enable = true;

      privateKeyFile = config.age.secrets.p2p-vpn-key.path;

      address = [ "10.2.0.2/32" ];
      dns = [ "10.2.0.1" ];

      peer = {
        endpoint = "138.199.33.236:51820";
        publicKey = "8kyi2e0ziUqhs+ooJYYI0yaVhv/bneUC1fhV5X2q/SE=";
      };

      portForwarding = {
        enable = false;
        gateway = "10.2.0.1";
      };
    };

    media.deluge = {
      enable = true;
      downloadPath = "/data/downloads/torrents";
      networkInterface = "wg0";
    };
  };

  microvm.shares = [
    {
      source = "/var/lib/media-server-test";
      mountPoint = "/data";
      tag = "media";
      proto = "virtiofs";
    }
  ];

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedTlsSettings = false;

    virtualHosts."${config.networking.hostName}" = {
      forceSSL = false;
      enableACME = false;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.modules.media.deluge.port}";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };
  };
}
