{ pkgs, ... }: {
  services.nix-daemon.enable = true;
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [ my-neovim ];
}
