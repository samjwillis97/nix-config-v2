{ super, config, lib, pkgs, ... }:
# This quite useful to know
let
    hostName = super.meta.hostname or "no-existing-hostname";
    hostConfigFile = ./${hostName}.nix;
in
{
    imports = lib.optionals (builtins.pathExists hostConfigFile) [ hostConfigFile ];

    programs.autorandr = {
        enable = true;
        hooks = {
            postswitch = {
                notify-i3 = "${pkgs.i3}/bin/i3-msg restart";
                reset-wallpaper = "systemctl restart --user wallpaper.service";
            };
        };
    };
}
