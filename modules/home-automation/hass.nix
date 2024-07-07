{ config, lib, ... }:
with lib;
let
  cfg = config.modules.home-automation.hass;
in
{
  options.modules.home-automation.hass = {
    enable = mkEnableOption "Enable home-assistant service";

    reverseProxyOrigins = mkOption {
      type = with types; listOf string;
      default = [ ];
    };
  };

  # Home assistant is a PIA, you have to onboard a first time before configuration is used...

  # Lets start here: https://github.com/Mic92/dotfiles/blob/a6b4fda081c95f762cbe9cdbe8571e264756f602/nixos/eve/modules/home-assistant/default.nix

  # See: https://community.home-assistant.io/t/configuration-not-honored-during-initial-onboarding-process/196178/14
  config = mkIf cfg.enable {
    services.home-assistant = {
      enable = true;

      openFirewall = true;

      # configWritable = true;
      extraComponents = [
        "xiaomi_miio"
        "shelly"
      ];

      config = {
        config = { };
        mobile_app = { };
        cloud = { };
        network = { };
        zeroconf = { };
        system_health = { };
        default_config = { };
        system_log = { };
        shopping_list = { };
        backup = { };
        sun = { };
        frontend = { };

        http = mkIf (cfg.reverseProxyOrigins != [ ]) {
          use_x_forwarded_for = true;
          trusted_proxies = cfg.reverseProxyOrigins;
        };

        homeassistant = {
          name = "Home";

          latitude = 32.9274;
          longitude = 151.7836;
          elevation = 10;

          unit_system = "metric";
          currency = "AUD";
          country = "AU";
          time_zone = config.time.timeZone;
          temperature_unit = "C";
          language = "en";

          internal_url = "http://localhost:8123";
        };

        logger.default = "info";
      };
    };
  };
}
