{ pkgs, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  programs.ghostty = {
    enable = true;

    systemd.enable = if isDarwin then false else true;

    settings = {
      title = "Ghostty";
      macos-titlebar-style = "hidden";
      cursor-style = "block";
      font-feature = "-calt";
      font-thicken = true;
      shell-integration-features = "no-cursor, title";
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
