{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.media.plex;

  mediaUserEnabled = config.modules.system.users.media;

  user = if mediaUserEnabled then "media" else "plex";
  group = if mediaUserEnabled then "media" else "plex";
in
{
  options.modules.media.plex = {
    enable = mkEnableOption "Enables Plex service";

    dataDirectory = mkOption {
      type = types.str;
      default = "/var/lib/plex";
      description = "Path to Plex data directory";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.setupPlex = lib.stringAfter [ "var" ]''
      ${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDirectory}
      ${pkgs.coreutils}/bin/chown -R ${user}:${group} ${cfg.dataDirectory}
    '';

    services.plex = {
      enable = true;

      openFirewall = true;

      dataDir = cfg.dataDirectory;

      user = user;
      group = group;
    };
  };
}
