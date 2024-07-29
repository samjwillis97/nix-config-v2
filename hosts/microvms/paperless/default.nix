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

      buckets = with config.age.secrets; [
        {
          mountLocation = "/data";

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
}
