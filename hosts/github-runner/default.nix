{ flake, pkgs, ... }:
{
  services.tailscale.enable = true;

  environment.systemPackages = with pkgs; [ tailscale ];

  nix = import ../../shared/nix.nix { inherit pkgs flake; };

  system.stateVersion = 5;
}
