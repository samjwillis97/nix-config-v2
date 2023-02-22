{ super, home, ... }:
{
    imports = [
        ../../home-manager/meta
        ../../home-manager/cli
    ] ++ super.extraHomeModules;

    # TODO: Put in initial hashed password etc.
}
