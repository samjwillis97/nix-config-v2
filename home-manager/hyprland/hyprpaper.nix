{ pkgs, ... }:
{
  services.hyprpaper = {
    enable = true;

    settings = {
      # prelod = pkgs.wallpapers.nixos-catppuccin-magenta-blue;
      #
      # wallpaper = [
      #   "DP-2, ${pkgs.wallpapers.nixos-catppuccin-magenta-blue}"
      #   "DP-3, ${pkgs.wallpapers.nixos-catppuccin-magenta-blue}"
      # ];
    };
  };
}
