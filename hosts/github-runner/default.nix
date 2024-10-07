{ flake, pkgs, ... }:
{
  services.tailscale.enable = true;

  environment.systemPackages = with pkgs; [ tailscale ];

  services.nix-daemon.enable = true;

  nix = import ../../shared/nix.nix { inherit pkgs flake; };

  system.stateVersion = 5;
}
