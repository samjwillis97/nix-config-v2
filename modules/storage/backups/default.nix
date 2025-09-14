{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.storage.backups;

  mountLocation = "/mnt/borg-backups";
  repoPath = mountLocation + "/" + config.networking.hostName;
in
{
  options.modules.storage.backups = {
    enable = mkEnableOption "Enable borg backups via. s3";

    s3BucketNameFile = mkOption {
      type = types.str;
      default = "/etc/borg-backups-s3-bucket";
      description = "S3 bucket to store borg backups";
    };

    awsRegionFile = mkOption {
      type = types.str;
      default = "/etc/borg-backups-aws-region";
    };

    awsAccessKeyIdFile = mkOption {
      type = types.str;
      default = "/etc/borg-backups-aws-access-key-id";
    };

    awsAccessKeySecretFile = mkOption {
      type = types.str;
      default = "/etc/borg-backups-aws-access-secret-id";
    };

    backupPaths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of paths to back up";
    };

    excludePaths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of paths to exclude from backup";
    };

    passphraseFile = mkOption {
      type = types.str;
      default = "/etc/borg-backups-passphrase";
      description = "File containing the passphrase for borg backups";
    };
  };

  config = mkIf cfg.enable {
    modules.storage.s3 = {
      enable = true;
      buckets = [
        {
          mountLocation = mountLocation;
          bucketNameFile = cfg.s3BucketNameFile;
          bucketRegionFile = cfg.awsRegionFile;
          awsAccessKeyIdFile = cfg.awsAccessKeyIdFile;
          awsSecretAccessKeyFile = cfg.awsAccessKeySecretFile;
        }
      ];
    };

    services.borgbackup.jobs.localToS3 = {
      doInit = true;
      paths = cfg.backupPaths;
      exclude = cfg.excludePaths;
      repo = repoPath;
      encryption = {
        mode = "repokey";
        passCommand = "cat ${cfg.passphraseFile}";
      };
      compression = "auto,lzma";
      startAt = "daily";
    };
  };
}
