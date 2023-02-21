{ config, home, ... }:
{
    imports = [
        ../../home-manager/meta
        ../../home-manager/cli
    ] ++ config.meta.extraHomeModules;

    # TODO: Put in initial hashed password etc.
}
