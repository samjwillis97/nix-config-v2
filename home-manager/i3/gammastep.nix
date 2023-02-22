{ config, lib, pkgs, ... }:
{
    services.gammastep = {
        enable = true;
        tray = true;
        dawnTime = "6:30-7:30";
        duskTime = "19:30-20:30";
        package = pkgs.gammastep;
        temperature = {
            day = 5700;
            night = 3700;
        };
        settings = {
            general = {
                gamma = 0.8;
                fade = 1;
            };
        };
    };
}
