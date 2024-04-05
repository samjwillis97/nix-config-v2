{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.ssh = {
    enable = true;
    compression = true;
    forwardAgent = true;
  };

  home.packages = with pkgs; [ mosh ];
}
