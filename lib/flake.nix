{ self, nixpkgs, darwin, home-manager, flake-utils, ... }@inputs:
let inherit (flake-utils.lib) mkApp;
in {
  /* TODO: Things to understand about this style
     - What does the @inputs do?
     - What are the specialArgs used for - I believe this is how you pass arguments through home-manager
     - how does flake get passed through
     - What is self?
  */

  mkNixosSystem = { hostname, system, username, networkAdapterName ? "en01"
    , extraModules ? [ ], extraHomeModules ? [ ]
    , nixosSystem ? nixpkgs.lib.nixosSystem, useHomeManager ? true, ... }: {
      nixosConfigurations.${hostname} = nixosSystem {
        inherit system;
        modules = [ ../hosts/${hostname} inputs.agenix.nixosModules.default ]
          ++ extraModules;
        specialArgs = {
          inherit system;
          flake = self;
          super.meta = {
            inherit username extraHomeModules networkAdapterName hostname
              useHomeManager;
            isDarwin = false;
          };
        };
      };
    };

  mkDarwinSystem = { hostname, system, username ? "samwillis"
    , extraModules ? [ ], extraHomeModules ? [ ]
    , darwinSystem ? darwin.lib.darwinSystem, ... }: {
      darwinConfigurations.${hostname} = darwinSystem {
        inherit system;
        modules = [ ../hosts/${hostname} inputs.agenix.darwinModules.default ]
          ++ extraModules;
        specialArgs = {
          inherit system;
          flake = self;
          super.meta = {
            hostname = hostname;
            isDarwin = true;
            username = username;
            extraHomeModules = extraHomeModules;
          };
        };
      };
    };

  mkHomeManager = { hostname, username ? "sam", homePath ? "/home"
    , system ? "x86_64-linux", extraHomeModules ? [ ], isDarwin ? false
    , homeManagerConfiguration ? home-manager.lib.homeManagerConfiguration, ...
    }:
    let
      pkgs = import nixpkgs { inherit system; };
      homeDirectory = "${homePath}/${username}";
    in {
      homeConfigurations.${hostname} = homeManagerConfiguration rec {
        inherit pkgs;
        modules = [
          ({ ... }: {
            home = { inherit username homeDirectory; };
            imports = [ ../users/${username} ] ++ extraHomeModules;
          })
        ];
        extraSpecialArgs = {
          inherit system;
          flake = self;
          super.meta = {
            hostname = hostname;
            username = username;
            extraHomeModules = extraHomeModules;
            isDarwin = isDarwin;
          };
        };
      };
    };
}
