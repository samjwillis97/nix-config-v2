{ config, ... }:
{
  imports = [
    ../../../modules/media/radarr
    ../../../modules/media/recyclarr
    ../../../modules/system/users
  ];

  networking.hostName = "curator";

  modules.system.users.media = true;

  modules.media = {
    radarr = {
      enable = true;
      config = {
        port = 9090;
        torrentClient = {
          enable = true;
          implementation = "Deluge";
          host = "iso-grabber";
          password = "deluge";
        };
      };
    };

    recyclarr = {
      enable = true;
      radarr = {
        enable = true;
        url = "http://localhost:${toString config.modules.media.radarr.config.port}";
        apiKey = config.modules.media.radarr.config.apiKey;
      };
    };
  };

  microvm.shares = [
    {
      source = "/var/lib/media-server-test";
      mountPoint = "/data";
      tag = "media";
      proto = "virtiofs";
      securityModel = "none";
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
        proxyPass = "http://127.0.0.1:${toString config.modules.media.radarr.config.port}";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };
  };
}
