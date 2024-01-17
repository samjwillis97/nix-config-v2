{ pkgs, ... }:
let
  create-blank-flake-template = pkgs.writeShellScriptBin "create-blank-flake-template" ''
    if [[ -f "flake.nix" ]]; then
      ${pkgs.gum}/bin/gum log --level error "flake.nix already exists - exiting"
      exit 1
    fi

    if [[ -f ".envrc" ]]; then
      ${pkgs.gum}/bin/gum log --level error ".envrc already exists - exiting"
      exit 1
    fi

    # Gen files
    touch .envrc && echo 'use flake .' > .envrc

    cat > "flake.nix" <<EOF
{
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  flake-utils.url = "github:numtide/flake-utils";
};
outputs = { self, nixpkgs, flake-utils }:
  flake-utils.lib.eachDefaultSystem
    (system:
      let
        overlays = [ ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in
      with pkgs;
      {
        devShells.default = mkShell {
          buildInputs = [ ];
        };
      }
    );
}
EOF

    direnv allow
  '';

  create-nix-shell = pkgs.writeShellScriptBin "create-nix-shell" ''
    environment=$(${pkgs.gum}/bin/gum choose --header "What type of environment?" \
    "blank flake" \
    "nodejs" \
    )

    case $environment in
      "blank flake")
        ${create-blank-flake-template}/bin/create-blank-flake-template
        exit 0
      ;;
      "nodejs")
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
