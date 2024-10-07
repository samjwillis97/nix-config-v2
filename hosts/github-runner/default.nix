{ ... }:
{
  imports = [ ../../nix-darwin/tailscale.nix ];

  services.nix-daemon.enable = true;

  system.stateVersion = 5;
}
