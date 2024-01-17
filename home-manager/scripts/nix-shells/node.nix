{ pkgs, ... }:
let 
  gum = pkgs.gum;

  create-node-nix-shell-env = pkgs.writeShellScriptBin "create-node-nix-shell-env" ''
    # Check if shell.nix OR .envrc exists
    if [[ -f "shell.nix" ]]; then
      ${gum}/bin/gum log --level error "shell.nix already exists - exiting"
      exit 1
    fi

    if [[ -f ".envrc" ]]; then
      ${gum}/bin/gum log --level error ".envrc already exists - exiting"
      exit 1
    fi

    # Ask for version
    version=$(${gum}/bin/gum choose --header "Which version of node?" "18" "20" "21")

    # Gen files
    touch .envrc && echo 'use nix' > .envrc

    cat > "shell.nix" <<EOF
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in

pkgs.mkShell {
  packages = with pkgs; [
    nodejs_$version
  ];

  shellHook = '''
    export PATH=\$PWD/node_modules/.bin/:\$PATH
  ''';
}
EOF

    direnv allow
  '';

  create-node-nix-flake-env = pkgs.writeShellScriptBin "create-node-nix-flake-env" ''
    # Check if shell.nix OR .envrc exists
    if [[ -f "flake.nix" ]]; then
      ${gum}/bin/gum log --level error "flake.nix already exists - exiting"
      exit 1
    fi

    if [[ -f ".envrc" ]]; then
      ${gum}/bin/gum log --level error ".envrc already exists - exiting"
      exit 1
    fi

    # Ask for version
    version=$(${gum}/bin/gum choose --header "Which version of node?" "18" "20" "21")

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
          buildInputs = [
            nodejs_$version
          ];
        };
      }
    );
}
EOF

    direnv allow
  '';
in {
  home.packages = [
    gum
    create-node-nix-shell-env
    create-node-nix-flake-env
  ];
}
