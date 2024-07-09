{ config, ... }:
{
  imports = [
    ../../../modules/media/sonarr
    ../../../modules/media/recyclarr
  ];

  networking.hostName = "sonarr";

  modules.media = {
    sonarr = {
      enable = true;
    };

    recyclarr = {
      enable = true;
      sonarr = {
        enable = true;
        url = "http://localhost:${toString config.modules.media.sonarr.config.port}";
        apiKey = config.modules.media.sonarr.config.apiKey;
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
        proxyPass = "http://127.0.0.1:${toString config.modules.media.sonarr.config.port}";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };
  };
}
