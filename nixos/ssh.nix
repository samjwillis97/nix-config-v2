{ super, lib, pkgs, ... }:
let inherit (super.meta) username;
in {
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    # TODO: Look at ghuntley configuration - looks like it only allows tailscale which is ideal
  };

  # TODO: SSH Keys

  programs.mosh.enable = true;
}
