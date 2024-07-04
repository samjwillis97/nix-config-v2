{ ... }:
{
  imports = [ ../../modules/home-automation/hass.nix ];

  modules.home-automation.hass.enable = true;

  networking.hostName = "my-first-microvm";
}
