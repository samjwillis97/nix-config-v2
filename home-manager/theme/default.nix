{ super, config, pkgs, lib, ... }:
{
  imports = [
    ../../modules/theme.nix
  ];

  theme = {
    /* fonts = { */
    /*   gui = { */
    /*     package = pkgs.roboto; */
    /*     name = "Roboto"; */
    /*   }; */
    /* }; */
    /* colors = with builtins; fromJSON (readFile ./colors.json); */
    wallpaper.path = lib.mkDefault pkgs.wallpapers.nixos-catppuccin-magenta-blue;
  };
}
