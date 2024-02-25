{ config, ... }: 
{
  users.users.root.password = "";
  
  # Ensure we're using networkd
  networking.useNetworkd = true;


  # Thanks again Jay
  # systemd = {
    # Very basic config asking for DHCP via eth interfaces
    # network.networks."00-wired" = {
    #   enable = true;
    #   matchConfig.Name = "enp*";
    #   networkConfig.DHCP = "yes";
    # };
  # };

  environment.etc."machine-id" = {
    mode = "0644";
    text = builtins.hashString "md5" config.networking.hostName + "\n";
  };

  fileSystems = {
    # "/var/lib".neededForBoot = true;
    "/var/agenix".neededForBoot = true;
  };

  microvm = {
    interfaces = [{
      id = config.networking.hostName;
      type = "user";
      mac = "02:42:c0:a8:04:83";
    }];
    # interfaces = [{
    #   type = "macvtap";
    #   id = config.networking.hostName;
    #   mac = "02:42:c0:a8:04:83";
    #   macvtap = {
    #     link = "wlp7s0";
    #     mode = "bridge";
    #   };
    # }];

    forwardPorts = [
      # SSH into the VM via 2222
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }
      {
        from = "guest";
        host.port = 8123;
        guest.port = 8123;
      }
    ];

    # volumes = [{
    #   mountPoint = "/var";
    #   image = "var.img";
    #   size = 256;
    # }];

    shares = [
      {
        # use "virtiofs" for MicroVMs that are started by systemd
        proto = "virtiofs";
        tag = "ro-store";
        # a host's /nix/store will be picked up so that no
        # squashfs/erofs will be built for it.
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }
      {
        source = "/var/agenix";
        mountPoint = "/var/agenix";
        proto = "virtiofs";
        tag = "secrets";
      }
      # Pass journald logs back to the host as per 
      # https://astro.github.io/microvm.nix/faq.html#how-to-centralize-logging-with-journald
      {
        # On the host
        source = "/var/lib/microvms/${config.networking.hostName}/journal";
        # In the MicroVM
        mountPoint = "/var/log/journal";
        tag = "journal";
        proto = "virtiofs";
        socket = "journal.sock";
      }
    ];

    hypervisor = "qemu";
    socket = "control.socket";
  };
}
