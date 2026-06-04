{ pkgs, ... }:
{
  stylix = {
    targets = {
      fontconfig = {
        enable = true;
        fonts.enable = true;
      };
    };
    cursor = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 16;
    };
  };
}
