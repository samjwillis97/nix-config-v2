{ config, lib, ... }:
with lib;
let
  cfg = config.modules.virtualisation.podman;
in
{
  options.modules.virtualisation.podman = {
    enable = mkEnableOption "Enables podman";
  };

  config = mkIf cfg.enable {
    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;

        defaultNetwork.settings = {
          dns_enabled = true;
        };
      };

      oci-containers = {
        backend = "podman";
      };
    };
  };
}
