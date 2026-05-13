{ pkgs, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  programs.ghostty = {
    enable = true;

    systemd.enable = true;

    settings = {
      title = " ";
      macos-titlebar-style = "hidden";
      cursor-style = "block";
      font-feature = "-calt";
      font-thicken = true;
      shell-integration-features = "no-cursor";
    }
    // (
      if isDarwin then
        {

          window-colorspace = "display-p3";
        }
      else
        { }
    );
  };
}
