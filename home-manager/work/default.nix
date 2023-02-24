# TODO:
#   - Teams
{ pkgs, ... }:
{
    home.packages = with pkgs; [
        # Clashing or something?
        /* teams */

        mongodb-5_0
    ];

    # TODO: Get mongodb-memory-server working by exporting the path
    /* environment.variables.MONGOMS_SYSTEM_BINARY= "${pkgs.mongodb-5_0}/bin/mongod"; */
}
