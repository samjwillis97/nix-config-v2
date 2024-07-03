{
  flake,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.virtualisation.microvm-host;

  # inherit
  # (import ../../lib/flake.nix {
  #   self = flake;
  #   nixpkgs = flake.inputs.nixpkgs;
  #   darwin = flake.inputs.darwin;
  #   home-manager = flake.inputs.home-manager;
  #   flake-utils = flake.inputs.flake-utils;
  #   agenix = flake.inputs.agenix;
  #   microvm = flake.inputs.microvm;
  # })
  # mkMicroVm2
  # ;

  vmConfig =
    with types;
    (submodule {
      options = {
        hostname = mkOption {
          type = str;
          description = "The hostname of the VM";
        };
        modules = mkOption {
          type = listOf submodule;
          default = [ ];
        };
      };
    });
in
{
  # Rethink this..
  imports = [ flake.inputs.microvm.nixosModules.host ];

  options.modules.virtualisation.microvm-host = {
    enable = mkEnableOption "Enables being a microvm host";

    vms = mkOption {
      type = with types; listOf vmConfig;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    networking = {
      useNetworkd = true;
      nat = {
        enable = true;
        enableIPv6 = true;
        externalInterface = "wlp7s0";
        internalInterfaces = [ "microvm" ];
      };
      hosts = { 
        "10.0.0.2" = [ "my-first-microvm.local" "my-first-microvm.microvm"  ];
      };
    };

    # Number for the bridge must be lower than devices attached to the bridge
    # This is to ensure bridge is loaded before others
    systemd.network = {
      enable = true;
      # Defines network device called microvm
      # as a bridge
      netdevs."10-microvm".netdevConfig = {
        Kind = "bridge";
        Name = "microvm";
      };

      # Network configuration
      networks = {
        "10-microvm" = {
          matchConfig.Name = "microvm"; # Applies to devices named microvm
          networkConfig = {
            DHCPServer = false;
          };
          addresses = [
            { addressConfig.Address = "10.0.0.1/24"; }
            { addressConfig.Address = "fd12:3456:789a::1/64"; }
          ];
        };
        "11-microvm" = {
          matchConfig.Name = "vm-*";
          networkConfig = {
            Bridge = "microvm";
          };
        };
      };
    };

    # Allow inbound traffic for the DHCP server
    networking.firewall.allowedUDPPorts = [ 67 ];

    microvm = {
      autostart = builtins.map (v: v.hostname) cfg.vms;

      vms = builtins.foldl' (
        acc: v:
        acc
        // {
          ${v.hostname} = {
            config = {
              imports = [
                flake.inputs.agenix.nixosModules.default
                ../../secrets
                ../../modules/networking/tailscale
              ];

              networking.hostName = "my-first-microvm-2";
              networking.firewall.allowedTCPPorts = [ 22 ];

              services.openssh = {
                enable = true;
                settings = {
                  PermitRootLogin = "yes";
                  # PasswordAuthentication = false;
                };
              };

              # TODO: Need agenix duh
              modules.networking.tailscale = {
                enable = true;
                authKeyFile = config.age.secrets."tailscale_pre-auth".path;
              };

              systemd.network.networks = {
                "10-lan" = {
                  matchConfig.Name = "en*";
                  networkConfig = {
                    Address = [ "10.0.0.2/24" ];
                    Gateway = "10.0.0.1";
                    DNS = [
                      "10.0.0.1"
                      "1.1.1.1"
                    ];
                  };
                };
              };

              users.users.root = {
                password = "nixos";
              };

              users.users.sam = {
                isNormalUser = true;
                password = "nixos";
                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA2FeFN6YQEUr22lJCeuQHcDawLuAPnoizlZLJOwhch4 sam@williscloud.org"
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYyMM/qTTLsXdPvvfkhdufg9gLYOI2y8d1oDpAgI0ft samjwillis97@gmail.com"
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENzw8pIt2UVGWcXUx4E4AxxWj8zA+DLZSp0y7RGK5VW samuel.willis@nib.com.au"
                ];
              };

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

          };
        }
      ) { } cfg.vms;
    };
  };
}
