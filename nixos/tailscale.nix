{ config, ... }:
{
  imports = [
    ../secrets/default
    ../modules/networking/tailscale
  ];

  modules.networking.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets."tailscale_pre-auth".path;
  };
}
