{ pkgs, ... }:
{
  services.tailscale.enable = true;

  environment.systemPackages = with pkgs; [ tailscale ];

  services.nix-daemon.enable = true;

  system.stateVersion = 5;
}
