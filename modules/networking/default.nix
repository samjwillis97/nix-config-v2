{ config, lib, ... }:
with lib;
let
  cfg = config.modules.networking;
in
{
  options.modules.networking = {
    mdns = {
      enable = mkOption {
        description = "Enables mDNS";
        type = types.bool;
        default = true;
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.mdns.enable ({

      services.avahi = {
        enable = true;
        nssmdns4 = true;
        nssmdns6 = true;

        publish = {
          enable = true;
          # domain = true;
          addresses = true;
        };
      };
    }))
  ];
}
