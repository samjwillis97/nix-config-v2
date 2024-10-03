{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../nixos
    ../../modules/ops/deploy.nix
    ../../modules/monitoring/exporters
    ../../modules/monitoring/promtail
    ../../modules/virtualisation/microvm-host.nix
  ];

  modules = {
    ops.deploy = {
      createDeployUser = true;
    };

    monitoring = {
      promtail = {
        enable = true;
        lokiUrl = "http://insights:3100";
      };

      exporters.system.enable = true;
    };

    virtualisation.microvm-host = {
      enable = true;
      externalInterface = "enp2s0";
      vms = [
        "graphy"
        "insights"
        "radarr"
        "cache"
      ];
    };
  };

  fileSystems."/mnt/nas" = {
    device = "192.168.4.119:/volume1/nas";
    fsType = "nfs";
    options = [ "nfsvers=4.1" ];
  };
}
