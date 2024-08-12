{
  super,
  flake,
  system,
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

      home-manager = {
        enable = mkEnableOption "Enable home-manager for standard user";
        extraModules = mkOption {
          type = types.listOf types.anything;
          default = [ ];
          description = "Extra home-manager modules to include";
        };
      };

      addDeployerSSHKey = mkEnableOption "Add deployer SSH key to standard user";
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

      users =
        {
          media = mkIf cfg.media {
            isSystemUser = true;
            group = "media";
            uid = 980;
            shell = pkgs.bash;
          };
        }
        // (
          if cfg.standardUser.enable then
            {
              ${cfg.standardUser.username} = {
                isNormalUser = true;
                uid = 1000;
                shell = if cfg.standardUser.home-manager.enable then pkgs.zsh else pkgs.bash;
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
            }
          else
            { }
        );
    };

    programs.zsh = mkIf (cfg.standardUser.enable && cfg.standardUser.home-manager.enable) {
      enable = true;
    };

    home-manager = mkIf (cfg.standardUser.enable && cfg.standardUser.home-manager.enable) {
      useUserPackages = true;
      users.${cfg.standardUser.username} = {
        imports = [
          flake.inputs.agenix.homeManagerModules.age
          ../../../home-manager/meta
          ../../../home-manager/cli
          ../../../home-manager/theme
        ] ++ cfg.standardUser.home-manager.extraModules;
      };
      extraSpecialArgs = {
        inherit flake system super;
      };
    };
  };
}
