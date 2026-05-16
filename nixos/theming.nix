{ pkgs, ... }:
{
  stylix = {
    cursor = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 16;
    };
  };
}
