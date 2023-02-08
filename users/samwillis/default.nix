{ home, ... }:
{
    imports = [
        ../../home-manager/cli
        ../../home-manager/alacritty
    ];

    home.stateVersion = "22.11";

    # TODO: Put in initial hashed password etc.
}
