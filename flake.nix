{
  description = "My Home Manager configuration ☺️";

  inputs = {
    # Nixpkgs Source
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    # nix-darwin module
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-darwin = {
      url = "github:bandithedoge/nixpkgs-firefox-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager Source
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland Window Manager
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

    devenv = {
      url = "github:cachix/devenv/latest";
    };

    modular-neovim = {
      url = "github:samjwillis97/modular-neovim-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-serve = {
      url = "github:samjwillis97/nix-serve?ref=priority_change";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
    };

    microvm = {
      url = "github:astro/microvm.nix";
      # follows = "nixpkgs";
    };

    f = {
      url = "github:samjwillis97/f";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shc = {
      url = "github:samjwillis97/shc-2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    # Newer experimental Brew replacement
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nur,
      flake-utils,
      devenv,
      modular-neovim,
      agenix,
      nix-serve,
      hyprland,
      microvm,
      f,
      shc,
      deploy-rs,
      firefox-darwin,
      ...
    }@inputs:
    let
      inherit (import ./lib/attrsets.nix { inherit (nixpkgs) lib; }) recursiveMergeAttrs;
      inherit (import ./lib/flake.nix inputs) mkNixosSystem mkDarwinSystem mkHomeManager;
    in
    # Thoughts on how to compose this - Jays config is making more sense now...
    # Need a way to define systems, i.e. I have a macbook that runs aarch64-darwin and has these users
    # Need a way to define users properly, and what imports they will require no matter what (think of this like normal dotfiles)
    # On the system level define what pacakges to install, probably using the modules 
    # Think about how to use this just to replace dotfile management as well
    # A simple way to define sets of packages could be good as well
    # Then think of a way to replace docker.. i.e. pihole.nix
    # Still need to work out how to know what output to use...
    (recursiveMergeAttrs [
      # TODO: Convert these to a whole lot of enables
      # - i3
      # - Audio
      # - Dev
      (mkNixosSystem {
        hostname = "personal-desktop";
        system = "x86_64-linux";
        username = "sam";
        # networkAdapterName = "enp9s0";
        networkAdapterName = "wlp7s0";
        extraModules = [
          # microvm.nixosModules.host
          ./nixos/xserver.nix
          # ./nixos/wayland.nix
          ./nixos/fonts.nix
          ./nixos/audio.nix
          ./nixos/gaming.nix
          ./nixos/logitech.nix
          ./nixos/docker.nix
        ];
        extraHomeModules = [
          # hyprland.homeManagerModules.default
          ./home-manager/nixos.nix
          ./home-manager/desktop
          ./home-manager/i3
          ./home-manager/gaming
          ./home-manager/dev
          ./home-manager/dev/ops.nix
          # ./home-manager/qutebrowser
          # ./home-manager/hyprland
        ];
      })

      (mkNixosSystem {
        hostname = "linux-vm";
        system = "x86_64-linux";
        username = "sam";
        extraModules = [ ./services/coder ];
        extraHomeModules = [ ];
        useHomeManager = false;
      })

      (mkNixosSystem {
        hostname = "linux-amd64-vm";
        system = "aarch64-linux";
        username = "sam";
        extraModules = [ ./services/coder ];
        extraHomeModules = [ ];
        useHomeManager = false;
      })

      (mkNixosSystem {
        hostname = "mac-vm";
        system = "aarch64-linux";
        username = "sam";
        extraModules = [
          {
            modules.home-automation.hass = {
              enable = true;
            };
          }
        ];
        extraHomeModules = [ ];
        useHomeManager = true;
      })

      (mkDarwinSystem {
        hostname = "github-runner";
        system = "aarch64-darwin";
        useHomeManager = false;
      })

      (mkDarwinSystem {
        hostname = "Sams-MacBook-Air";
        system = "aarch64-darwin";
        username = "sam";
        homePath = "/Users";
        extraModules = [ ];
        extraHomeModules = [
          # ./home-manager/darwin/keyboard.nix
          ./home-manager/wezterm
          ./home-manager/vscode
          ./home-manager/dev
          ./home-manager/dev/devenv.nix
          ./home-manager/dev/ops.nix
          ./home-manager/aerospace
          ./home-manager/darwin
          ./home-manager/social
          ./home-manager/firefox
          ./home-manager/cache
          { modules.darwin.work = false; }
        ];
      })

      (mkDarwinSystem {
        hostname = "work-mbp";
        system = "aarch64-darwin";
        username = "samuel.willis";
        homePath = "/Users";
        extraModules = [ ];
        extraHomeModules = [
          ./home-manager/dev
          ./home-manager/dev/devenv.nix
          ./home-manager/dev/ops.nix
          ./home-manager/wezterm
          ./home-manager/vscode
          ./home-manager/work
          ./home-manager/aerospace
          ./home-manager/darwin
          ./home-manager/social
          ./home-manager/firefox
          { modules.darwin.work = true; }
        ];
      })

      (mkHomeManager { hostname = "coder-container"; })

      (mkNixosSystem {
        hostname = "teeny-pc";
        system = "x86_64-linux";
        username = "sam";
        extraHomeModules = [ ];
        extraModules = [ ./nixos/microvm-host.nix ];
        useHomeManager = false;
      })

      # This currently is just to let me format with `nix fmt` on any system
      (flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import self.inputs.nixpkgs { inherit system; };
        in
        {
          formatter = pkgs.nixfmt-rfc-style;
        }
      ))

      ({
        deploy.nodes.teeny-pc = {
          hostname = "teeny-pc";
          profiles.system = {
            user = "root";
            sshUser = "deployer";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.teeny-pc;
          };
        };

        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      })
    ]);
}
