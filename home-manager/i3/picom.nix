{ config, lib, pkgs, ... }:
{
    services.picom = {
        enable = true;
        backend = "glx";
        fade = true;
        fadeDelta = 2;
        vSync = true;
        settings = {
            unredir-if-possible = true;
            unredir-if-possible-exclue = [ "name *= 'Firefox'"];
        };
    };
}
