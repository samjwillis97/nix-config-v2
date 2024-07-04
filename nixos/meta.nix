{
  config,
  pkgs,
  flake,
  system,
  ...
}:

{
  # Add some Nix related packages
  environment.systemPackages = with pkgs; [
    cachix
    nix-build-uncached
    # nixos-cleanup
  ];

  nix = import ../shared/nix.nix { inherit pkgs flake; };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "24.05"; # Did you read the comment?

  # TODO: Look at ../shared/nix.nix in Thio

  # TODO: Get formatter working
  # formatter = pkgs.legacyPackages.${system}.nixfmt;

  # Enable unfree packages
  nixpkgs.config.allowUnfree = true;
}
