{ pkgs, ... }:
{
  nix-flake-template = pkgs.writeShellScriptBin "blank-nix-flake-template" ''
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

            # for dev shells nativeBuildInputs and buildInputs make no difference
            # though buildInputs are needed at run-time while nativeBuildInputs
            # are things only needed at compile time

            nativeBuildInputs = with pkgs; [];

            buildInputs = with pkgs; [];
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
}
