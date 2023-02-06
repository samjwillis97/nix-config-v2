{ self }:
{
    generate-user-config = {
        flake
        ,config
        ,pkgs
        ,user-settings
        ,modules
        ,overrides ? { }
        , ... 
    }:
    with builtins;
    let
        inherit (stdenv) isLinux;
        inherit (lib) recursiveUpdate;

        inherit (user-settings) name;

        home = if isLinux then "/home/${name}" else "/Users/${name}";

        defaultHome = {
            stateVersion = "22.05";
        };
    in recursiveUpdate overrides {
        users.users.${name} = recursiveUpdate { shell = pkgs.zsh; } user-settings;

        home-manager.users.${name} = (if hasAttr "home" user-settings then {
            home = recursiveUpdate defaultHome user-settings.home;
        } else {
            home = defaultHome;
        }) // {
            imports = modules;
        };
    };
}
