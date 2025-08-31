{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.storage.rclone;
in
{
  options.modules.storage.rclone = {
    enable = lib.mkEnableOption "Enables rclone setup";

    mounts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              settings = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                default = {  };
                description = "Rclone mount settings";
              };

              mountLocation = lib.mkOption {
                type = lib.types.str;
                default = "/mnt/rclone/${name}";
                description = "Location to mount the remote to";
              };

              deviceOptions = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Additional options to pass to rclone mount command";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable (
    let
      configFiles = lib.mapAttrs (name: value: 
        pkgs.writeText "${name}-rclone.conf" ''
          [${name}]
          ${
            builtins.concatStringsSep "\n" (
              lib.mapAttrsToList (k: v: "${k} = ${v}") value.settings
            )
          }
        ''
      ) cfg.mounts;
    in
    {
      environment.systemPackages = with pkgs; [
        rclone
        fuse
      ];

      fileSystems = lib.mapAttrs (name: value:
        {
          device = "${name}:";
          mountPoint = value.mountLocation;
          fsType = "rclone";
          options = value.deviceOptions ++ [
            "config=${configFiles.${name}}"
          ];
        }
      ) cfg.mounts;
    }
  );
}
