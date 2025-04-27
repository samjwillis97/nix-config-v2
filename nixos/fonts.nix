{ pkgs, ... }:
{

  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;

    packages = with pkgs; [
      corefonts
      noto-fonts
      noto-fonts-emoji
      nerd-fonts.fira-mono
      nerd-fonts.jetbrains-mono
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "FiraCode Nerd Font Mono" ];
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        emoji = [
          "Noto Color Emoji"
          "Noto Emoji"
        ];
      };
    };
  };
}
