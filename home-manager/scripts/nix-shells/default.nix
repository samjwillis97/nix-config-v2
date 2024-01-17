{ pkgs, ... }:
let
  create-nix-shell = pkgs.writeShellScriptBin "create-nix-shell" ''
    environment=$(${pkgs.gum}/bin/gum choose --header "What type of environment?" "nodejs")

    case $environment in
      nodejs)
        # NOTE: would be nice to reference this a bit better
        create-node-nix-shell-env
        exit 0
      ;;
    esac
  '';
in
{
  imports = [
    ./node.nix
  ];

  home.packages = [
    pkgs.gum
    create-nix-shell
  ];
}
