{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.storage.backups;

  localRepoPath = "/var/backups/borg";
in
{
  options.modules.storage.backups = {
    enable = mkEnableOption "Enable borg backups";

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
    # system.activationScripts.setupBorgRepoDir = lib.stringAfter [ "var" ]''
    #   ${pkgs.coreutils}/bin/mkdir -p ${localRepoPath}
    # '';

    services.borgbackup.jobs.localToS3 = {
      doInit = true;
      paths = cfg.backupPaths;
      exclude = cfg.excludePaths ++ [ localRepoPath ];
      repo = localRepoPath;
      encryption = {
        mode = "repokey";
        passCommand = "cat ${cfg.passphraseFile}";
      };
      compression = "auto,lzma";
      startAt = "daily";
    };
  };
}
