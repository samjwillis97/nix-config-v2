{
  description = "My Home Manager configuration ☺️";

  inputs = {
    # Nixpkgs Source
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };

    # nix-darwin module
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager Source
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = { url = "github:numtide/flake-utils"; };

    nur = { url = "github:nix-community/NUR"; };

    devenv = { url = "github:cachix/devenv/latest"; };

    my-neovim = { url = "github:samjwillis97/neovim-flake"; };

    agenix = { url = "github:ryantm/agenix"; };

    # Additional Neovim Plugins
    nixneovimplugins = { url = "github:jooooscha/nixpkgs-vim-extra-plugins"; };
  };

  outputs = { self, nixpkgs, nur, flake-utils, devenv, my-neovim
    , nixneovimplugins, agenix, ... }@inputs:
    let
      lib = nixpkgs.lib;
      inherit (import ./lib/attrsets.nix { inherit (nixpkgs) lib; })
        recursiveMergeAttrs mergeMap;
      inherit (import ./lib/flake.nix inputs)
        mkNixosSystem mkDarwinSystem mkHomeManager;
      # Thoughts on how to compose this - Jays config is making more sense now...
      # Need a way to define systems, i.e. I have a macbook that runs aarch64-darwin and has these users
      # Need a way to define users properly, and what imports they will require no matter what (think of this like normal dotfiles)
      # On the system level define what pacakges to install, probably using the modules 
      # Think about how to use this just to replace dotfile management as well
      # A simple way to define sets of packages could be good as well
      # Then think of a way to replace docker.. i.e. pihole.nix
      # Still need to work out how to know what output to use...

    in (recursiveMergeAttrs [
      # TODO: Convert these to a whole lot of enables
      # - i3
      # - Audio
      # - Dev
      (mkNixosSystem {
        hostname = "personal-desktop";
        system = "x86_64-linux";
        username = "sam";
        networkAdapterName = "enp9s0";
        extraModules = [
          ./nixos/xserver.nix
          ./nixos/fonts.nix
          ./nixos/audio.nix
          ./nixos/gaming.nix
          ./nixos/logitech.nix
          ./nixos/docker.nix
        ];
        extraHomeModules = [
          ./home-manager/nixos.nix
          ./home-manager/desktop
          ./home-manager/i3
          ./home-manager/gaming
          ./home-manager/dev
          ./home-manager/work
          ./home-manager/ides
          ./home-manager/qutebrowser
        ];
      })

      (mkNixosSystem {
        hostname = "linux-vm";
        system = "x86_64-linux";
        username = "sam";
        extraModules = [ ./services/coder.nix ];
        extraHomeModules = [ ];
        useHomeManager = false;
      })

      (mkNixosSystem {
        hostname = "linux-amd64-vm";
        system = "aarch64-linux";
        username = "sam";
        extraModules = [ ./services/coder.nix ];
        extraHomeModules = [ ];
        useHomeManager = false;
      })

      (mkDarwinSystem {
        hostname = "Sams-MacBook-Air";
        system = "aarch64-darwin";
        username = "samwillis";
        homePath = "/Users";
        extraHomeModules = [
          ./home-manager/alacritty
          ./home-manager/wezterm
          ./home-manager/dev/rust.nix
          ./home-manager/dev/devenv.nix
          ./home-manager/dev/node.nix
        ];
      })

      (mkHomeManager { hostname = "amp-7150"; })
      (mkHomeManager {
        hostname = "amp-8060";
        extraHomeModules = [
          # TODO: firefox
          ./home-manager/nixos.nix
          ./home-manager/kitty
          # ./home-manager/alacritty
          ./home-manager/dev
          ./home-manager/work
        ];
      })
    ]);
}
