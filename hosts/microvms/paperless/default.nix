{ config, pkgs, ... }:
let 
  paperlessDataDir = "/data";
  backupDirectory = "/backups";
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
            mountLocation = backupDirectory;

            bucketNameFile = paperless-s3-backup-bucket-name.path;
            bucketRegionFile = paperless-s3-bucket-region.path;

            awsAccessKeyIdFile = infra-access-key-id.path;
            awsSecretAccessKeyFile = infra-secret-access-key.path;
          }
        ];
      };
    };
  };

  # Make sure rclone mount is up first
  systemd.services.paperless-scheduler.after = ["data.mount"];
  systemd.services.paperless-consumer.after = ["data.mount"];
  systemd.services.paperless-web.after = ["data.mount"];

  # Backs up the SQLite database
  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 * * * *    root    ${pkgs.rclone}/bin/rclone copy ${config.services.paperless.dataDir}/db.sqlite3 ${backupDirectory}/db"
    ];
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
