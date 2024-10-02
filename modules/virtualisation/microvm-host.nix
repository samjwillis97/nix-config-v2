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

    # Jesus...
    services.openssh.knownHosts = builtins.foldl' (
      acc: hostname:
      acc
      // {
        "${hostname}-ed25519" = {
          hostNames = [
            "${hostNameToIp.${hostname}}"
            "${hostname}.local"
            "${hostname}.microvm"
          ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIvUEHBrNHACMPnim1iHfGwHfnFm9edX/vMFL5vcU0c";
        };
        "${hostname}-rsa" = {
          hostNames = [
            "${hostNameToIp.${hostname}}"
            "${hostname}.local"
            "${hostname}.microvm"
          ];
          publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDaeZx/Xt0idqy4dFspSg1t17OrF0nAMShldjpJAAHG0DVZxbMGWP1bhxRsxGfGFdnXcwl+pgF+griv8qZGNmZdhR5uDBGgscH4kqVhLxi6sUs5mapMikFTERb6lPNngrE8An4saGD14G+NOH8xHtQtP9VqxqDSmwjn6/A8gfYzVyLOyqn14bBXKRDqL8sPPOMWQ5AZM057QOaCUGyjJXbLLy/dQ5oB48cfOY5HOs9tbDR2qYvTCoufH0CWVHSRiLeWdRU1OaqqOcJD1uy0R4wyccrfWVDvB26ZEzFySXSLPvq2flWykBXEiN+7m2PqAdLTGY+wJH8X5LiQuTKqw989Vlq2mQnTOBUpJMQy7rk43VuydsR0Sf8tzQYTLxokPhMkgRs4PEigjwVIV+EuCUn62PU0Ypcf0tdGnMI578DEPCEuGikSIT2MUx7pKLz2hSwjCcZhnmUr1YPsxH9xaGE2FLOwdhHiuITUGML6becBC6fVKNX6TQiN4osYbpcniP0= root@personal-desktop";
        };
        "${hostname}-ecdsa" = {
          hostNames = [
            "${hostNameToIp.${hostname}}"
            "${hostname}.local"
            "${hostname}.microvm"
          ];
          publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJL53srucY8y1ebQ75RZel3bziVk8Y34S5yjU2OkqgItEFNeJJfu2u8Y+6Xu3a126y+VAmg53FVzgC6NwYH58H0= root@personal-desktop";
        };
      }
    ) { } cfg.vms;

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
        acc: hostname:
        acc
        // {
          ${hostname} = {
            config =
              { config, ... }:
              {
                imports = [
                  flake.inputs.agenix.nixosModules.default
                  flake.inputs.home-manager.nixosModules.home-manager
                  ./microvm-guest.nix
                  ../networking/tailscale
                  ../../secrets/microvm
                  ../../hosts/microvms/${hostname}
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
                      Address = [ "${hostNameToIp.${hostname}}/24" ];
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
