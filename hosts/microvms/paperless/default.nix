{ config, ... }:
{
  imports = [
    ../../../modules/monitoring/exporters
    ../../../modules/monitoring/promtail
    ../../../modules/storage/s3
  ];

  networking.hostName = "paperless";

  modules = {
    monitoring = {
      promtail = {
        enable = true;
        lokiUrl = "http://insights:3100";
      };

      exporters.system.enable = true;
    };

    storage.s3 = {
      enable = true;

      buckets = [
        {
          mountLocation = "/data";

          bucketNameFile = config.age.secrets.paperless-s3-bucket-name.path;
          bucketRegionFile = config.age.secrets.paperless-s3-bucket-region.path;

          awsAccessKeyIdFile = config.age.secrets.infra-access-key-id.path;
          awsSecretAccessKeyFile = config.age.secrets.infra-secret-access-key.path;
        }
        {
          mountLocation = "/backups";

          bucketNameFile = config.age.secrets.paperless-s3-backup-bucket-name.path;
          bucketRegionFile = config.age.secrets.paperless-s3-bucket-region.path;

          awsAccessKeyIdFile = config.age.secrets.infra-access-key-id.path;
          awsSecretAccessKeyFile = config.age.secrets.infra-secret-access-key.path;
        }
      ];
    };
  };
}
