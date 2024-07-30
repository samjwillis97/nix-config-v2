{ config, ... }:
let 
  paperlessDataDir = "/data";
in
{
  imports = [
    ../../../modules/monitoring/exporters
    ../../../modules/monitoring/promtail
    ../../../modules/storage/s3
    ../../../modules/storage/paperless
  ];

  networking.hostName = "paperless";
  microvm.mem = 4096;

  modules = {
    monitoring = {
      promtail = {
        enable = true;
        lokiUrl = "http://insights:3100";
      };

      exporters.system.enable = true;
    };

    storage = {
      paperless = {
        enable = true;
        documentDir = paperlessDataDir;
      };

      s3 = {
        enable = true;

        buckets = with config.age.secrets; [
          {
            mountLocation = paperlessDataDir;

            bucketNameFile = paperless-s3-bucket-name.path;
            bucketRegionFile = paperless-s3-bucket-region.path;

            awsAccessKeyIdFile = infra-access-key-id.path;
            awsSecretAccessKeyFile = infra-secret-access-key.path;
          }
          {
            mountLocation = "/backups";

            bucketNameFile = paperless-s3-backup-bucket-name.path;
            bucketRegionFile = paperless-s3-bucket-region.path;

            awsAccessKeyIdFile = infra-access-key-id.path;
            awsSecretAccessKeyFile = infra-secret-access-key.path;
          }
        ];
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
        proxyPass = "http://127.0.0.1:${toString config.modules.storage.paperless.port}";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };
  };
}
