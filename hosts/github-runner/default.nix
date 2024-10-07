{ ... }:
{
  services.tailscale.enable = true;

  services.nix-daemon.enable = true;

  system.stateVersion = 5;
}
