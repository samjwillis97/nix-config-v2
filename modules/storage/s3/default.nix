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

    # TODO: https://nixos.wiki/wiki/Agenix#Replace_inplace_strings_with_secrets
    # So need to write a service to replace all those values before the rclone service 
    # actually starts, ez right
    # A useful pattern to know

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
