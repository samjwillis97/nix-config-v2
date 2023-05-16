# TODO:
#   - Teams
{ pkgs, ... }:
{
    home.packages = with pkgs; [
        # FIXME:
        # Commenting out for a bit.. MS killed the download URL and haven't done anything about it :) 
        # See: https://github.com/NixOS/nixpkgs/issues/217473
        # FIX: 
        #  nix-prefetch-url 'https://web.archive.org/web/20221130115842if_/https://packages.microsoft.com/repos/ms-teams/pool/main/t/teams/teams_1.5.00.23861_amd64.deb' 'sha256-h0YnCeJX//l4TegJVZtavV3HrxjYUF2Fa5KmaYmZW8E='
        teams
        libreoffice
        remmina
    ];

    # TODO: Get mongodb-memory-server working by exporting the path
    /* environment.variables.MONGOMS_SYSTEM_BINARY= "${pkgs.mongodb-5_0}/bin/mongod"; */
}
