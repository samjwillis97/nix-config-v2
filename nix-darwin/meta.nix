{ pkgs, flake, ... }: {
  environment.systemPackages = with pkgs; [ cachix ];
  services.nix-daemon.enable = true;
  nix = import ../shared/nix.nix { inherit pkgs flake; };
}
