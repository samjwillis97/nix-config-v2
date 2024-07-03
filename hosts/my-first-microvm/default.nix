{ ... }:
{
  networking = {
    hostName = "my-first-microvm";
    firewall.allowedTCPPorts = [ 22 ];
    useNetworkd = true;
  };
  users.users.root.password = "";

  fileSystems = {
    "/var/agenix".neededForBoot = true;
  };

  microvm = {
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
        proto = "9p";
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
}
