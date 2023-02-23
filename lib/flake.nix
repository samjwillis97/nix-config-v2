{ self, nixpkgs, darwin, home-manager, flake-utils, ... }@inputs:
let
    inherit (flake-utils.lib) mkApp;
in
{
    /* TODO: Things to understand about this style
    - What does the @inputs do?
    - What are the specialArgs used for - I believe this is how you pass arguments through home-manager
    - how does flake get passed through
    - What is self?
    */

    mkNixosSystem = {
        hostname
        ,system
        ,username
        ,extraModules ? []
        ,extraHomeModules ? []
        ,nixosSystem ? nixpkgs.lib.nixosSystem
        ,...
    }:
    {
        nixosConfigurations.${hostname} = nixosSystem {
            inherit system;
            modules = [ ../hosts/${hostname} ] ++ extraModules;
            specialArgs = {
                inherit system;
                flake = self;
                super.meta = {
                    inherit username extraHomeModules;
                };
                /* super.meta.extraHomeModules = extraHomeModules; */
            };
        };
    };

    mkDarwinSystem = {
        hostname
        ,system
        ,username ? "samwillis"
        ,extraModules ? []
        ,extraHomeModules ? []
        ,darwinSystem ? darwin.lib.darwinSystem
        ,...
    }:
    {
        darwinConfigurations.${hostname} = darwinSystem {
            inherit system;
            modules = [ ../hosts/${hostname} ] ++ extraModules;
            specialArgs = {
                inherit system;
                flake = self;
                super.meta = {
                    username = username;
                    extraHomeModules = extraHomeModules;
                };
            };
        };
    };

    mkHomeManager = {
        hostname
        ,username ? "sam"
        ,homePath ? "/home"
        ,system ? "x86_64-linux"
        ,extraHomeModules ? []
        ,homeManagerConfiguration ? home-manager.lib.homeManagerConfiguration
        ,...
    }:
    let
        pkgs = import nixpkgs { inherit system; };
        homeDirectory = "${homePath}/${username}";
    in
    {
        homeConfigurations.${hostname} = homeManagerConfiguration rec {
            inherit pkgs;
            modules = [
                ({...}: {
                    home = { inherit username homeDirectory; };
                    imports = [ ../users/${username} ] ++ extraHomeModules;
                })
            ];
            extraSpecialArgs = {
                inherit system;
                flake = self;
                super = {
                    meta.username = username;
                    # see configPath in thiagoko
                };
            };
        };
    };
}
