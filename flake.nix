{
    description = "My Home Manager configuration ☺️";

    inputs = {
        # Nixpkgs Source
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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

    };

    outputs = { nixpkgs, home-manager, darwin, ... }:
    let
        lib = nixpkgs.lib;
        inherit (import ./lib/attrsets.nix { inherit (nixpkgs) lib; }) recursiveMergeAttrs mergeMap;

        nixosHosts = [];
        darwinHosts = [
            {
                hostname = "Sams-MacBook-Air";
                system = "aarch64-darwin";
                username = "samwillis";
                homePath = "/Users";
            }
        ];

        mkDarwinSystem = {
            hostname
            ,system
            ,extraModules ? []
            ,...
        }:
        {
            darwinConfigurations.${hostname} =
                darwin.lib.darwinSystem {
                    inherit system;
                    modules = [
                        ./hosts/${hostname}
                        home-manager.darwinModules.home-manager
                        {
                            home-manager.useGlobalPkgs = true;
                            home-manager.useUserPackages = true;
                            home-manager.users.samwillis = import ./users/samwillis;
                        }
                    ] ++ extraModules;
                    specialArgs = {
                        inherit system;
                    };
                };
        };

        mkNixosSystem = {
            hostname,
            system,
            ...
        }:
        {
            nixosConfigurations."${hostname}" = {
                hostname = nixpkgs.lib.nixosSystem {
                    system = system;
                    modules = [
                    ];
                };
            };
        };

        mkHomeManager = {
            hostname
            ,username ? "sam"
            ,homePath ? "/home"
            ,system ? "x86_64-linux"
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
                        imports = [ ./users/${username} ];
                    })
                ];
                extraSpecialArgs = {
                    inherit system;
                    super = {
                        meta.username = username;
                        # see configPath in thiagoko
                    };
                };
            };
            # see apps... in thiagoko
        };

        # Thoughts on how to compose this - Jays config is making more sense now...
        # Need a way to define systems, i.e. I have a macbook that runs aarch64-darwin and has these users
        # Need a way to define users properly, and what imports they will require no matter what (think of this like normal dotfiles)
        # On the system level define what pacakges to install, probably using the modules 
        # Think about how to use this just to replace dotfile management as well
        # A simple way to define sets of packages could be good as well
        # Then think of a way to replace docker.. i.e. pihole.nix
        # Still need to work out how to know what output to use...
    in 
        (recursiveMergeAttrs [
            (mergeMap (map mkNixosSystem nixosHosts))
            (mergeMap (map mkDarwinSystem darwinHosts))
            (mergeMap (map mkHomeManager darwinHosts))
        ]);
}
