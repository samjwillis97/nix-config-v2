{ config, lib, pkgs, ... }:
let inherit (config.meta) username;
in {
  services.openssh = {
    enable = true;
    settings.passwordAuthentication = false;
    # TODO: Look at ghuntley configuration - looks like it only allows tailscale which is ideal
  };

  # TODO: SSH Keys

  programs.mosh.enable = true;
}
