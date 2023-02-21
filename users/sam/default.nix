{ super, config, home, ... }:
{
    imports = [
        ../../home-manager/meta
        ../../home-manager/cli
    ] ++ config.extraHomeModules;

    # TODO: Put in initial hashed password etc.
}
