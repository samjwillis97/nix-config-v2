{ config, lib, pkgs, ... }: {
  programs.neovim = {
    # TODO: Configure
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # package = pkgs.my-neovim;
  };
}
