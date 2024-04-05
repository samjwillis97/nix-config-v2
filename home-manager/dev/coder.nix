{ pkgs, ... }:
{
  home.packages = with pkgs; [ coder ];
}
