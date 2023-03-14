{ pkgs, ... }:
{
    home.packages = with pkgs; [
        /* mongodb-5_0 */
        /* robo3t */
        mongodb-compass
        mongodb-tools
    ];

    # TODO: Get mongodb-memory-server working by exporting the path
    /* environment.variables.MONGOMS_SYSTEM_BINARY= "${pkgs.mongodb-5_0}/bin/mongod"; */
}
