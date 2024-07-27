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
    environment.etc."rclone-mnt.conf".text = ''
      [remote]
      type = s3
      provider = AWS
      env_auth = false
      access_key_id = XXX
      secret_access_key = YYY
      region = us-east-1
      endpoint =
      location_constraint =
      acl = private
      server_side_encryption =
      storage_class =    ;
    '';

    # fileSystems."/mnt" = {
    #   device = "remote:/my_data";
    #   fsType = "rclone";
    #   options = [
    #     "nodev"
    #     "nofail"
    #     "allow_other"
    #     "args2env"
    #     "config=/etc/rclone-mnt.conf"
    #   ];
    # };
  };
}
