{ config, ... }:
{
  imports = [
    ../../modules/media/radarr
    ../../modules/media/recyclarr
  ];

  networking.hostName = "curator";

  modules.media = {
    radarr = {
      enable = true;
      config = {
        port = 9090;
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
