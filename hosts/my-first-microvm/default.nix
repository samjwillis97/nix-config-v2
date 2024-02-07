{ ... }: {
  networking.hostName = "my-first-microvm";
  users.users.root.password = "";

  microvm = {
    volumes = [{

      mountPoint = "/var";
      image = "var.img";
      size = 256;
    }];
    shares = [{

      # use "virtiofs" for MicroVMs that are started by systemd
      proto = "9p";
      tag = "ro-store";
      # a host's /nix/store will be picked up so that no
      # squashfs/erofs will be built for it.
      source = "/nix/store";
      mountPoint = "/nix/.ro-store";
    }];
    hypervisor = "qemu";
    socket = "control.socket";
  };
}
