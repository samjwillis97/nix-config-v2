{ pkgs, ... }: {
  home.packages = with pkgs; [
    jq
    direnv
    difftastic
    nodePackages.json-diff
    _1password
    neovim-full
    nodePackages.wrangler
  ];
}
