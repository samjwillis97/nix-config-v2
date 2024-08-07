{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.storage.paperless;
in
{
  options.modules.storage.paperless = {
    enable = mkEnableOption "Enable paperless";

    port = mkOption {
      default = 28981;
      type = types.port;
    };

    documentDir = mkOption {
      default = "/var/lib/paperless/media";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    services.paperless = {
      enable = true;

      address = "0.0.0.0";
      port = cfg.port;
      mediaDir = cfg.documentDir;

      passwordFile = pkgs.writeTextFile {
        name = "paperless-superuser-password";
        text = "admin";
      };
    };
  };
}
