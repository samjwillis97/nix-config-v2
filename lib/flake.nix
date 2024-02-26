{ self, nixpkgs, darwin, home-manager, flake-utils, ... }@inputs:
let inherit (flake-utils.lib) mkApp;
in {
  /* TODO: Things to understand about this style
     - What does the @inputs do?
     - What are the specialArgs used for - I believe this is how you pass arguments through home-manager
     - how does flake get passed through
     - What is self?
  */

  mkMicroVm = { hostname, system, extraModules ? [ ]
    , nixosSystem ? nixpkgs.lib.nixosSystem }: {
      nixosConfigurations.${hostname} = nixosSystem {
        inherit system;
        modules = [
          inputs.microvm.nixosModules.microvm
          inputs.agenix.nixosModules.default
          ../nixos
          ../hosts/${hostname}
          ../shared
        ] ++ extraModules;
        specialArgs = {
          inherit system;
          flake = self;
          super.meta = {
            inherit hostname;
            username = "sam-vm";
            isDarwin = false;
            useHomeManager = false;
          };
        };
      };

      defaultPackage.${system} = self.packages.${system}.${hostname};

      packages.${system} = {
        ${hostname} =
          self.nixosConfigurations.${hostname}.config.microvm.declaredRunner;
      };
    };

  mkNixosSystem = { hostname, system, username, networkAdapterName ? "en01"
    , extraModules ? [ ], extraHomeModules ? [ ]
    , nixosSystem ? nixpkgs.lib.nixosSystem, useHomeManager ? true, ... }:
    let
      baseModule = {
        meta = {
          inherit hostname username networkAdapterName useHomeManager;
          isDarwin = false;
        };
      };
    in {
      nixosConfigurations.${hostname} = nixosSystem {
        inherit system;
        modules = [
          (baseModule // { meta.extraHomeModules = extraHomeModules; })
          ../hosts/${hostname}
          inputs.agenix.nixosModules.default
          ../shared
        ] ++ extraModules;
        specialArgs = {
          inherit system;
          flake = self;
          super.meta = {
            inherit username networkAdapterName hostname useHomeManager;
            extraHomeModules = [ inputs.agenix.homeManagerModules.age ]
              ++ extraHomeModules;
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
        modules =
          [ ../hosts/${hostname} inputs.agenix.darwinModules.default ../shared ]
          ++ extraModules;
        specialArgs = {
          inherit system;
          flake = self;
          super.meta = {
            hostname = hostname;
            isDarwin = true;
            username = username;
            extraHomeModules = [ inputs.agenix.homeManagerModules.age ]
              ++ extraHomeModules;
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
            extraHomeModules = [ inputs.agenix.homeManagerModules.age ]
              ++ extraHomeModules;
            isDarwin = isDarwin;
          };
        };
      };
    };
}
