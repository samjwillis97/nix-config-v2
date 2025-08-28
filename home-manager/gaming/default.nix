{ pkgs, ... }:
{
  home.packages = with pkgs; [ 
    # runescape
    runelite
  ];
}
