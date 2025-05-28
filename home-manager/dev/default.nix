{
  super,
  pkgs,
  flake,
  system,
  ...
}:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
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
      _1password-cli
      neovim
      dive # docker image explorer
      # Disabling SHC whilst still doing more dev
      # shc-cli
      mtr # network tool
      iperf # network performance tool
      devenv
    ]
    ++ (with pkgs; if isDarwin then [ f ] else [ inotify-info ]);
}
