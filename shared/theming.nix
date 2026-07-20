{ flake, pkgs, ... }:
{
  stylix = {
    enable = true;

    autoEnable = true;

    targets = {
      font-packages = {
        enable = true;
        fonts.enable = true;
      };
    };

    # image = pkgs.fetchurl {
    #   url = "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/refs/heads/main/os/nix-magenta-blue-1920x1080.png";
    #   hash = "sha256-CsBF3h4p0EEawF9aNDzm9DN+YoxyEnicc9n0oC8FCfs=";
    # };

    image = ../wallpapers/evening-sky.png;

    polarity = "dark";

    base16Scheme = "${flake.inputs.tt-schemes}/base16/catppuccin-mocha.yaml";

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font Mono";
      };

      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };

      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        desktop = 11;
        terminal = 11;
        applications = 10;
        popups = 10;
      };
    };

    opacity = {
      terminal = 1.0;
      desktop = 1.0;
      popups = 1.0;
    };
  };
}
