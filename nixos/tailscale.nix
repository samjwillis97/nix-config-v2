{ config, ... }: {
  imports = [ ../secrets ];

  modules.networking.tailscale = {
    enable = true;
    authKeyFile = config.age.secrets."tailscale_pre-auth".path;
  };
}
