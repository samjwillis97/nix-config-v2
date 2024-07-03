{
  flake,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.virtualisation.microvm-guest;
in
{
  options.modules.virtualisation.microvm-guest = {
    enable = mkEnableOption "Enables being a microvm guest";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        # PasswordAuthentication = false;
      };
    };

    networking.firewall.allowedTCPPorts = [ 22 ];

    networking.useNetworkd = true;

    fileSystems = {
      "/var/agenix".neededForBoot = true;
    };

    microvm = {
      interfaces = [
        {
          type = "tap";
          id = "vm-test1";
          mac = "02:00:00:00:00:01";
        }
      ];

      # volumes = [
      #   {

      #     mountPoint = "/var";
      #     image = "var.img";
      #     size = 256;
      #   }
      # ];
      shares = [
        {
          source = "/var/agenix";
          mountPoint = "/var/agenix";
          tag = "secrets";
          proto = "virtiofs";
        }
        {

          # use "virtiofs" for MicroVMs that are started by systemd
          proto = "9p";
          tag = "ro-store";
          # a host's /nix/store will be picked up so that no
          # squashfs/erofs will be built for it.
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
        }
      ];
      hypervisor = "qemu";
      socket = "control.socket";
    };
  };
}
