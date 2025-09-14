{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.storage.s3;

  baseConfigFile = pkgs.writeTextFile {
    name = "rclone-mnt.conf";
    text = ''
      [S3Remote]
      type = s3
      provider = AWS
      env_auth = false
      access_key_id = @access-key-id@
      secret_access_key = @secret-access-key@
      region = @bucket-region@
      endpoint =
      location_constraint =
      acl = private
      server_side_encryption =
      storage_class =    

      [bucket]
      type = alias
      remote = S3Remote:@bucket-name@
    '';
    # storage class is probably worth selecting..
    # I think endpoint is the bucket name essentially
  };

  bucket = {
    options = {
      mountLocation = mkOption { type = types.str; };

      bucketNameFile = mkOption { type = types.str; };
      bucketRegionFile = mkOption { type = types.str; };

      awsAccessKeyIdFile = mkOption { type = types.str; };
      awsSecretAccessKeyFile = mkOption { type = types.str; };
    };
  };
in
{
  options.modules.storage.s3 = {
    enable = mkEnableOption "Enables s3 storage mounting with rclone";

    buckets = mkOption {
      type = with types; listOf (submodule bucket);
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rclone ];

    system.activationScripts = builtins.listToAttrs (
      lib.imap1 (i: bucket: {
        name = "aws-rclone-secrets-${toString i}";
        value = ''
          configFile=/etc/rclone-mnt-${toString i}.conf
          ${pkgs.coreutils}/bin/cp ${baseConfigFile} $configFile

          secret=$(cat "${bucket.awsAccessKeyIdFile}")
          ${pkgs.gnused}/bin/sed -i "s#@access-key-id@#$secret#" "$configFile"

          secret=$(cat "${bucket.awsSecretAccessKeyFile}")
          ${pkgs.gnused}/bin/sed -i "s#@secret-access-key@#$secret#" "$configFile"

          secret=$(cat "${bucket.bucketNameFile}")
          ${pkgs.gnused}/bin/sed -i "s#@bucket-name@#$secret#" "$configFile"

          secret=$(cat "${bucket.bucketRegionFile}")
          ${pkgs.gnused}/bin/sed -i "s#@bucket-region@#$secret#" "$configFile"
        '';
      }) cfg.buckets
    );

    fileSystems = builtins.listToAttrs (
      lib.imap1 (i: bucket: {
        name = bucket.mountLocation;
        value = {
          device = "bucket:/";
          fsType = "rclone";
          options = [
            "nodev"
            "nofail"
            "allow_other"
            "args2env"
            "config=/etc/rclone-mnt-${toString i}.conf"
          ];
        };
      }) cfg.buckets
    );
  };
}
