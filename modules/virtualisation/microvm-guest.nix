{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.virtualisation.microvm-guest;
  hostname = config.networking.hostName;
in
{
  options.modules.virtualisation.microvm-guest = {
    enable = mkEnableOption "Enables being a microvm guest";
  };

  config = mkIf cfg.enable {

    users.users.root = {
      password = "";
      # Think about moving these somewhere central like 
      # https://github.com/JayRovacsek/nix-config/blob/0f18ebf54033e291bee32bf52171676514563862/common/networking.nix#L191
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2FeFN6YQEUr22lJCeuQHcDawLuAPnoizlZLJOwhch4 sam@williscloud.org"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYyMM/qTTLsXdPvvfkhdufg9gLYOI2y8d1oDpAgI0ft samjwillis97@gmail.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENzw8pIt2UVGWcXUx4E4AxxWj8zA+DLZSp0y7RGK5VW samuel.willis@nib.com.au"
      ];
    };

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = false;
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
          source = "/var/agenix/${hostname}";
          mountPoint = "/var/agenix";
          tag = "secrets";
          proto = "virtiofs";
        }
        {
          # use "virtiofs" for MicroVMs that are started by systemd
          proto = "virtiofs";
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

    system.stateVersion = "24.05";
  };
}
