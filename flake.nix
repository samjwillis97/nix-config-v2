{
  description = "My Home Manager configuration ☺️";

  inputs = {
    # Nixpkgs Source
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    # nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Only being used for reducing flake lock duplications
    systems.url = "github:nix-systems/default";
    # crane.url = "github:ipetkov/crane";
    flake-compat.url = "github:edolstra/flake-compat";

    # nix-darwin module
    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager Source
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland Window Manager
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    nur.url = "github:nix-community/NUR";

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
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    microvm = {
      url = "github:astro/microvm.nix";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };

    f = {
      url = "github:samjwillis97/f";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    httpcraft = {
      url = "github:samjwillis97/shc-ai";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };

    attic = {
      url = "github:zhaofengli/attic";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        # crane.follows = "crane";
        flake-compat.follows = "flake-compat";
      };
    };

    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
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
      inputs = {
        nix-darwin.follows = "darwin";
        brew-api.follows = "brew-api";
      };
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";

    opencode-flake = {
      url = "github:aodhanhayter/opencode-flake";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nur,
      flake-utils,
      modular-neovim,
      agenix,
      nix-serve,
      hyprland,
      microvm,
      f,
      httpcraft,
      deploy-rs,
      firefox-darwin,
      opencode-flake,
      ...
    }@inputs:
    let
      inherit (import ./lib/attrsets.nix { inherit (nixpkgs) lib; }) recursiveMergeAttrs;
      inherit (import ./lib/flake.nix inputs) mkNixosSystem mkDarwinSystem;
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
        networkAdapterName = "enp9s0";
        # networkAdapterName = "wlp7s0";
        extraModules = [
          # microvm.nixosModules.host
          ./nixos/xserver.nix
          # ./nixos/wayland.nix
          ./nixos/fonts.nix
          ./nixos/audio.nix
          ./nixos/gaming.nix
          ./nixos/logitech.nix
          ./nixos/docker.nix
          (
            { config, ... }:
            {
              imports = [ ./secrets/mediaserver ];
              modules.virtualisation.docker = {
                enable = true;
                useHostNetwork = true;
              };

              modules.media = {
                plex.enable = true;

                zurg = {
                  enable = true;
                  realDebridTokenFile = config.age.secrets.real-debrid-token.path;
                  mount.enable = true;
                };

                cinesync = {
                  enable = true;

                  tmdbApiKeyFile = config.age.secrets.tmdb-api-key.path;

                  dependsOn = [
                    "zurg"
                    "rclone"
                  ];

                  directories.source = "${config.modules.media.zurg.mount.path}/torrents";

                  webInterface.authEnabled = false;

                  integrations = {
                    remoteStorage.enableMountVerification = true;
                    plex = {
                      enable = true;
                      url = "http://127.0.0.1:32400";
                      tokenFile = config.age.secrets.plex-token.path;
                    };
                  };
                };
                overseerr = {
                  enable = true;
                  openFirewall = true;
                  dmmBridge = {
                    enable = true;
                    overseerrApiKeyFile = config.age.secrets.overseerr-api-key.path;
                    traktApiKeyFile = config.age.secrets.trakt-api-key.path;
                    dmmAccessTokenFile = config.age.secrets.dmm-access-token.path;
                    dmmRefreshTokenFile = config.age.secrets.dmm-refresh-token.path;
                    dmmClientIdFile = config.age.secrets.dmm-client-id.path;
                    dmmClientSecretFile = config.age.secrets.dmm-client-secret.path;
                  };
                };
              };
            }
          )
        ];
        extraHomeModules = [
          # hyprland.homeManagerModules.default
          ./home-manager/nixos.nix
          ./home-manager/desktop
          ./home-manager/i3
          ./home-manager/gaming
          ./home-manager/dev
          ./home-manager/dev/ops.nix
          ./home-manager/dev/windsurf.nix
          ./home-manager/vscode
          ./home-manager/firefox
          # ./home-manager/qutebrowser
          # ./home-manager/hyprland
        ];
      })

      (mkNixosSystem {
        hostname = "linux-vm";
        system = "x86_64-linux";
        username = "sam";
        extraModules = [
          {
            modules.virtualisation.docker = {
              enable = true;
            };

            modules.media = {
              zurg = {
                enable = true;
                mount.enable = true;
              };
              cinesync = {
                enable = true;
              };
            };
          }
        ];
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
          ./home-manager/dev/ops.nix
          ./home-manager/dev/gemini.nix
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
          ./home-manager/dev/ops.nix
          ./home-manager/dev/cursor.nix
          ./home-manager/wezterm
          ./home-manager/vscode
          ./home-manager/work
          ./home-manager/aerospace
          ./home-manager/darwin
          ./home-manager/social
          ./home-manager/firefox
          ./home-manager/moonlight
          ./home-manager/opencode
          { modules.darwin.work = true; }
        ];
      })

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
