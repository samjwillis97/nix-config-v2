{ pkgs, ... }:
let
  create-node-envs = import ./node.nix { inherit pkgs; };
  create-templates = import ./blank.nix { inherit pkgs; };

  # NOTE: worth reading - https://fasterthanli.me/series/building-a-rust-service-with-nix/part-10#a-flake-with-a-dev-shell
  create-nix-shell = pkgs.writeShellScriptBin "create-nix-shell" ''
    environment=$(${pkgs.gum}/bin/gum choose --header "What type of environment?" \
    "blank flake" \
    "nodejs" \
    "nodejs flake" \
    )

    case $environment in
      "blank flake")
        ${create-templates.nix-flake-template}/bin/blank-nix-flake-template
        exit 0
      ;;
      "nodejs")
        ${create-node-envs.nix-shell-template}/bin/node-nix-shell-template
        exit 0
      ;;
      "nodejs flake")
        ${create-node-envs.nix-flake-template}/bin/node-nix-flake-template
        exit 0
      ;;
    esac
  '';
in
{
  home.packages = [
    pkgs.gum
    create-nix-shell
  ];
}
