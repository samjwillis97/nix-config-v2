{
  pkgs,
  config,
  lib,
  ...
}:
let
  binaryStoreCacheDir = "/cache";
in
{
  imports = [
    ../../../modules/media/homepage-dashboard
    ../../../modules/monitoring/exporters
    ../../../modules/monitoring/promtail
  ];

  networking.hostName = "cache";

  modules.monitoring = {
    promtail = {
      enable = true;
      lokiUrl = "http://insights:3100";
    };

    exporters.system.enable = true;
  };

  microvm.shares = [
    {
      source = "/mnt/nas/nix-store";
      mountPoint = binaryStoreCacheDir;
      tag = "media";
      proto = "virtiofs";
      securityModel = "none";
    }
  ];

  environment.systemPackages = with pkgs; [ attic-server ];

  services.minio = {
    enable = true;
    dataDir = [ binaryStoreCacheDir ];
    # accessKey = "my-access-key";
    # secretKey = "my-secret-key";
    rootCredentialsFile = pkgs.writeTextFile {
      name = "minio-root-credentials";
      text = ''
        MINIO_ROOT_USER=admin
        MINIO_ROOT_PASSWORD=admin
      '';
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
        proxyPass = "http://127.0.0.1:${toString config.services.nix-serve.port}";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };
  };
}
