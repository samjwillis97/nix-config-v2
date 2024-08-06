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
    standardUser = {
      enable = mkEnableOption "Enable standard user";

      username = mkOption {
        type = types.str;
        default = "sam";
        description = "Default username for standard user";
      };

      # FIXME: this should check another option instead of being manually set
      useHomeManager = mkEnableOption "Using home-manager?";
    };

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
      } // (if cfg.standardUser.enable then {
        ${cfg.standardUser.username} = {
          isNormalUser = true;
          uid = 1000;
          shell = if cfg.standardUser.useHomeManager then pkgs.zsh else pkgs.bash;
          extraGroups = [
            "wheel"
            "networkmanager"
            "video"
            "docker"
            "libvirtd"
            "qemu-libvirtd"
          ];
          password = "nixos";
          openssh = {
            authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2FeFN6YQEUr22lJCeuQHcDawLuAPnoizlZLJOwhch4 sam@williscloud.org"
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYyMM/qTTLsXdPvvfkhdufg9gLYOI2y8d1oDpAgI0ft samjwillis97@gmail.com"
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENzw8pIt2UVGWcXUx4E4AxxWj8zA+DLZSp0y7RGK5VW samuel.willis@nib.com.au"
            ];
          };
        };
      } else { });
    };
  };
}
