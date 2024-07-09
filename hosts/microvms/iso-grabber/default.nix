{ config, ... }:
{
  imports = [
    ../../../modules/networking/vpn
  ];

  networking.hostName = "iso-grabber";

  modules.networking.vpn = {
    enable = true;
  };
}
