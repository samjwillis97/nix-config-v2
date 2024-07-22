{ config, ... }:
{
  imports = [
    ../../../modules/networking/vpn
    ../../../modules/media/deluge
    ../../../modules/system/users
    ../../../modules/monitoring/exporters
  ];

  networking.hostName = "iso-grabber";

  modules.monitoring.exporters.system.enable = true;

  modules.system.users.media = true;

  modules = {
    networking.vpn = {
      enable = true;
    };

    media.deluge = {
      enable = true;
      downloadPath = "/data/downloads/torrents";
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
