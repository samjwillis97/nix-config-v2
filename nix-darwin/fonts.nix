{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
  ];
}
