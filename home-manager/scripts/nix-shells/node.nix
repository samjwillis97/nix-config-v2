{ pkgs, ... }:
let 
  fetch-available-node = pkgs.writeShellScriptBin "fetch-available-node" ''
    nix search nixpkgs nodejs --json | jq 'keys | map(select(contains(".nodejs_")) | sub(".*nodejs_"; "")) | join (" ")' | sed 's/.\(.*\)./\1/'
  '';

  ask-for-node-version = pkgs.writeShellScriptBin "ask-for-node-version" ''
    ${pkgs.gum}/bin/gum choose --header "Which version of node?" $(${fetch-available-node}/bin/fetch-available-node)
  '';

  node-nix-shell-template = pkgs.writeShellScriptBin "node-nix-shell-template" ''
    # Check if shell.nix OR .envrc exists
    if [[ -f "shell.nix" ]]; then
      ${pkgs.gum}/bin/gum log --level error "shell.nix already exists - exiting"
      exit 1
    fi

    if [[ -f ".envrc" ]]; then
      ${pkgs.gum}/bin/gum log --level error ".envrc already exists - exiting"
      exit 1
    fi

    # Ask for version
    version=$(${ask-for-node-version}/bin/ask-for-node-version)

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

  node-nix-flake-template = pkgs.writeShellScriptBin "node-nix-flake-template" ''
    # Check if shell.nix OR .envrc exists
    if [[ -f "flake.nix" ]]; then
      ${pkgs.gum}/bin/gum log --level error "flake.nix already exists - exiting"
      exit 1
    fi

    if [[ -f ".envrc" ]]; then
      ${pkgs.gum}/bin/gum log --level error ".envrc already exists - exiting"
      exit 1
    fi

    # Ask for version
    version=$(${ask-for-node-version}/bin/ask-for-node-version)

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

        nativeBuildInputs = with pkgs; [];
        buildInputs = with pkgs; [ nodejs_$version ];
      in
      with pkgs;
      {
        devShells.default = mkShell {
          inherit buildInputs nativeBuildInputs;
        };
      }
    );
}
EOF

    direnv allow
  '';
in {
  nix-shell-template = node-nix-shell-template;
  nix-flake-template = node-nix-flake-template;
}
