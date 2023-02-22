{ config, lib, pkgs, ... }:
let inherit (config.meta) username;
in
{
    services.openssh = {
        enable = true;
        settings.passwordAuthentication = true;
    };

    # TODO: SSH Keys

    programs.mosh.enable = true;
}
