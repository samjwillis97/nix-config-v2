{ config, ... }:
{
  imports = [
    ../../../modules/media/radarr
    ../../../modules/media/recyclarr
  ];

  networking.hostName = "curator";


  # TODO: I should mount the movies path to /data/media/movies
  #     downloades should be /data/downloads, /data/usenet, /data/torrents
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
