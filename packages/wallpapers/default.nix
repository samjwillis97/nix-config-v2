{ callPackage, fetchurl, lib }:

let
  mkWallpaper = callPackage (import ./mkWallpaper.nix) { };
in
{
  nixos-catppuccin-magenta-blue = mkWallpaper {
    name = "nixos-catppuccin-magenta-blue";
    ext = "png";
    url = "https://raw.githubusercontent.com/catppuccin/wallpapers/main/os/nix-magenta-blue-1920x1080.png";
    sha256 = "";
  };
}
