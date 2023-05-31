{ pkgs, ... }: {
  imports = [ ../overlays ../cachix.nix ];
  environment.systemPackages = with pkgs; [ cachix ];
  services.nix-daemon.enable = true;
  nixpkgs.config.allowUnfree = true;
}
