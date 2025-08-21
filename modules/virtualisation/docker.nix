{ config, lib, ... }:
with lib;
let
  cfg = config.modules.virtualisation.docker;
  standardUserEnabled = config.modules.system.users.standardUser.enable;
in
{
  options.modules.virtualisation.docker = {
    enable = mkEnableOption "Enables docker";

    useHostNetwork = mkOption {
      type = types.bool;
      default = false;
      description = "Use host network for Docker containers";
    };
  };

  config = mkIf cfg.enable {
    virtualisation = {
      docker = {
        enable = true;
      };

      oci-containers = {
        backend = "docker";
      };
    };

    users.users.${config.modules.system.users.standardUser.username}.extraGroups =
      mkIf standardUserEnabled
        [
          "docker"
        ];
  };
}
