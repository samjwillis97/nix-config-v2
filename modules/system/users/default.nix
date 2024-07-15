{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.system.users;
in
{
  options.modules.system.users = {
    media = mkEnableOption "Enable standard media user";
  };

  config = {
    users = {
      groups = {
        media = mkIf cfg.media {
          name = "media";
          gid = 980;
        };
      };

      users = {
        media = mkIf cfg.media {
          isSystemUser = true;
          group = "media";
          uid = 980;
          shell = pkgs.bash;
        };
      };
    };
  };
}
