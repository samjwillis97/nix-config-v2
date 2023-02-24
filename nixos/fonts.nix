{ pkgs, ... }:
{

    fonts = {
        enableDefaultFonts = true;
        fontDir.enable = true;

        fonts = with pkgs; [
            corefonts
            noto-fonts
            noto-fonts-emoji
            (nerdfonts.override { fonts = [ "FiraCode" ]; })
        ];
        # TODO: See if there are more preffered fonts

        fontconfig = {
            enable = true;
            defaultFonts = {
                monospace = ["FiraCode Nerd Font Mono"];
                serif = ["Noto Serif"];
                sansSerif = ["Noto Sans"];
                emoji = ["Noto Color Emoji" "Noto Emoji"];
            };
        };
    };

}
