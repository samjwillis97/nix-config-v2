{ pkgs, lib, ... }:
with lib;
let
  themeType = types.submodule {
    options = {
      package = mkOption {
        type = with types; nullOr package;
        description = "Theme package";
      };

      name = mkOption {
        type = types.str;
        description = "Theme name";
      };
    };
  };
in
{
  options.theme = {
    fonts = {
      gui = mkOption {
        type = types.nullOr themeType;
        description = "GUI main font";
      };

      dpi = mkOption {
        type = types.int;
        description = "Font dpi";
        default = 96;
      };
    };

    colors = mkOption {
      type = with types; attrsOf str;
      description = "Base16 colors";
    };

    wallpaper = {
      path = mkOption {
        type = types.path;
        description = "Wallpaper path";
      };
      scale = mkOption {
        type = types.enum [
          "tile"
          "center"
          "fill"
          "scale"
        ];
        default = "fill";
        description = "Wallpaper scaling";
      };
    };
  };
}
