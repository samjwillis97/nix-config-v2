{ config, ... }:
{
  imports = [ ../../../modules/monitoring ];

  networking.hostName = "insights";

  modules = {
    monitoring = {
      enable = true;

      exporters = {
        system = true;
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

      locations."/prometheus" = {
        proxyPass = "http://127.0.0.1:${toString config.modules.monitoring.prometheusPort}/";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };

      locations."/alloy" = {
        proxyPass = "http://127.0.0.1:${toString config.modules.monitoring.alloyPort}/";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };
  };
}
