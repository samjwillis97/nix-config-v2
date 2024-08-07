{ config, pkgs, ... }:
let
  paperlessDataDir = "/data";
  backupDirectory = "/backups";

  dbFile = "${config.services.paperless.dataDir}/db.sqlite3";
  dbBackupDirectory = "${backupDirectory}/${config.networking.hostName}";
  dbBackupFile = "${dbBackupDirectory}/db.sqlite3";
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
  systemd.services.paperless-scheduler.after = [
    "data.mount"
    "backup.mount"
    "paperless-db-backup-check.service"
  ];
  systemd.services.paperless-consumer.after = [
    "data.mount"
    "backup.mount"
    "paperless-db-backup-check.service"
  ];
  systemd.services.paperless-web.after = [
    "data.mount"
    "backup.mount"
    "paperless-db-backup-check.service"
  ];

  # Backs up the SQLite database
  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 * * * *    root    ${pkgs.rclone}/bin/rclone copy ${dbFile} ${dbBackupDirectory}"
    ];
  };

  systemd.services.paperless-db-backup-check = {
    description = "Copies db file from backup if one doesn't exist";

    after = [ "backup.mount" ];
    wants = [ "backup.mount" ];
    wantedBy = [
      "paperless-scheduler.service"
      "paperless-consumer.service"
      "paperless-web.service"
    ];

    serviceConfig.Type = "oneshot";

    script = ''
      dbFile=${dbFile}
      dbBackupFile=${dbBackupFile}
      if  [ ! -e "$dbFile" ]; then
        echo "DB file does not exists"

        if  [ ! -e "$dbBackupFile" ]; then
          echo "DB Backup does not exist"
        else
          echo "DB Backup exists"
          echo "Going to copy backup file"
          ${pkgs.coreutils}/bin/cp "$dbBackupFile" "$dbFile"
          ${pkgs.coreutils}/bin/chown ${config.services.paperless.user}:${config.services.paperless.user} "$dbFile"
          ${pkgs.coreutils}/bin/chmod 600 "$dbFile"
          echo "Backup copied"
        fi
      else
        echo "DB file already exists, skipping backup copy"
      fi
    '';
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
