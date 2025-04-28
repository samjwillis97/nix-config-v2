{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      windsurf
    ];
}
