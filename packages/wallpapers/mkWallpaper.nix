# Based on: https://github.com/Misterio77/nix-config/blob/a1b9f1706bd0f9e18b90191bfca4eddcd3f070a8/pkgs/wallpapers/wallpaper.nix
{
  lib,
  stdenvNoCC,
  fetchurl,
}:
{
  name,
  url,
  sha256,
  ext ? "jpg",
}:

stdenvNoCC.mkDerivation {
  name = "wallpaper-${name}.${ext}";
  src = fetchurl {
    inherit sha256;
    url = url;
  };
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm0644 "$src" "$out"
    runHook postInstall
  '';

  meta = with lib; {
    description = url;
    platforms = platforms.all;
    license = licenses.unfree;
  };
}
