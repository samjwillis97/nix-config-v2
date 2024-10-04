{ pkgs, ... }:
{
  home.packages = with pkgs; [ deploy-rs ];
}
