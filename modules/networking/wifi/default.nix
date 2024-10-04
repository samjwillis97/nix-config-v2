{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.networking.wifi;
  ssid = builtins.readFile config.age.secrets."home-wifi-SSID".path;
  psk = builtins.readFile config.age.secrets."home-wifi-PSK".path;
in
{
  imports = [ ../../../secrets/default/default.nix ];

  options.modules.networking.wifi = {
    enable = mkEnableOption "Enable wifi networking with systemd";

    adapter = mkOption {
      default = "wlp1s0";
      type = types.str;
    };

    networks = {
      home = mkEnableOption "Enable home network";
    };
  };

  config = mkIf cfg.enable {
    networking.wireless.enable = true;
    networking.wireless.networks = {
      ${ssid} = {
        psk = psk;
      };
    };
  };
}
