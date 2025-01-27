{
  super,
  pkgs,
  flake,
  system,
  ...
}:
{
  imports = [ ../../secrets/github ];
  home.packages =
    with pkgs;
    [
      gnupg1
      jq
      direnv
      difftastic
      nodePackages.json-diff
      _1password
      neovim
      dive # docker image explorer
      # Disabling SHC whilst still doing more dev
      # shc-cli
      mtr # network tool
      iperf # network performance tool
    ]
    ++ (with pkgs; if super.meta.isDarwin then [ f ] else [ ]);
}
