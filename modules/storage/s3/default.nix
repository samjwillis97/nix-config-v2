{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.storage.s3;
in
{
  options.modules.storage.s3 = {
    enable = mkEnableOption "Enables s3 storage mounting with rclone";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.rclone ];
    # See: https://forum.rclone.org/t/include-stuff-from-other-files-in-the-rclone-conf-file/21003/6
    # See: https://nixos.wiki/wiki/Agenix#Replace_inplace_strings_with_secrets
    system.activationScripts."aws-rclone-secrets" = let
      configFile = pkgs.writeTextFile {
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

          [paperless]
          type = alias
          remote = S3Remote:@bucket-name@
        '';
        # storage class is probably worth selecting..
        # I think endpoint is the bucket name essentially
      };
    in
    ''
      configFile=/etc/rclone-mnt.conf
      ${pkgs.coreutils}/bin/cp ${configFile} $configFile

      secret=$(cat "${config.age.secrets.infra-access-key-id.path}")
      ${pkgs.gnused}/bin/sed -i "s#@access-key-id@#$secret#" "$configFile"

      secret=$(cat "${config.age.secrets.infra-secret-access-key.path}")
      ${pkgs.gnused}/bin/sed -i "s#@secret-access-key@#$secret#" "$configFile"

      secret=$(cat "${config.age.secrets.paperless-s3-bucket-name.path}")
      ${pkgs.gnused}/bin/sed -i "s#@bucket-name@#$secret#" "$configFile"

      secret=$(cat "${config.age.secrets.paperless-s3-bucket-region.path}")
      ${pkgs.gnused}/bin/sed -i "s#@bucket-region@#$secret#" "$configFile"
    '';

    fileSystems."/mnt" = {
      device = "paperless:/";
      fsType = "rclone";
      options = [
        "nodev"
        "nofail"
        "allow_other"
        "args2env"
        "config=/etc/rclone-mnt.conf"
      ];
    };
  };
}
