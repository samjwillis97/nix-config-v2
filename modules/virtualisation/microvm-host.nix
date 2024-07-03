{
  flake,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.virtualisation.microvm-host;

  # vmConfig =
  #   with types;
  #   (submodule {
  #     options = {
  #       hostname = mkOption {
  #         type = str;
  #         description = "The hostname of the VM";
  #       };
  #       modules = mkOption {
  #         type = listOf submodule;
  #         default = [ ];
  #       };
  #     };
  #   });
in
{
  options.modules.virtualisation.microvm-host = {
    enable = mkEnableOption "Enables being a microvm host";

    vms = mkOption {
      type = with types; listOf string;
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
      autostart = cfg.vms;

      vms = builtins.foldl' (
        acc: v:
        acc
        // {
          ${v} = {
            config = {
              imports = [
                flake.inputs.agenix.nixosModules.default
                ../../nixos/tailscale.nix
                ../../hosts/${v}
                ./microvm-guest.nix
              ];

              modules.virtualisation.microvm-guest.enable = true;

              # Handle better here
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

            };

          };
        }
      ) { } cfg.vms;
    };
  };
}
