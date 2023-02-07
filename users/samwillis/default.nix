{ home, ... }:
{
    imports = [
        ../../home-manager/cli
    ];

    home.stateVersion = "22.11";

    # TODO: Put in initial hashed password etc.
}
