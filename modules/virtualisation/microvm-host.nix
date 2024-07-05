{
  flake,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.virtualisation.microvm-host;

  hostNameToIpList = lib.imap1 (i: v: {
    name = v;
    value = "10.0.0.${toString (i + 1)}";
  }) cfg.vms;

  hostNameToIp = builtins.listToAttrs hostNameToIpList;
in
{
  options.modules.virtualisation.microvm-host = {
    enable = mkEnableOption "Enables being a microvm host";

    externalInterface = mkOption {
      type = types.string;
      default = "wlp7s0";
    };

    vms = mkOption {
      type = with types; listOf string;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    networking =
      let
        hosts = lib.foldl (
          acc: v:
          acc
          // {
            ${v.value} = [
              "${v.name}.local"
              "${v.name}.microvm"
            ];
          }
        ) { } hostNameToIpList;
      in
      {
        hosts = hosts;

        useNetworkd = true;
        nat = {
          enable = true;
          enableIPv6 = true;
          externalInterface = cfg.externalInterface;
          internalInterfaces = [ "microvm" ];
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
                ../../secrets
                ../networking/tailscale
                ../../hosts/${v}
                ./microvm-guest.nix
              ];

              modules.virtualisation.microvm-guest.enable = true;

              modules.networking.tailscale = {
                enable = true;
                authKeyFile = config.age.secrets."microvm-tailscale".path;
              };

              systemd.network.networks = {
                "10-lan" = {
                  matchConfig.Name = "en*";
                  networkConfig = {
                    Address = [ "${hostNameToIp.${v}}/24" ];
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
