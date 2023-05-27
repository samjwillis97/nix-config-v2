{ super, config, lib, pkgs, flake, ... }:
let homeManager = if super.meta.useHomeManager then [ ./home.nix ] else [ ];
in {
  imports =
    [ ./meta.nix ./home.nix ./user.nix ./ssh.nix ./locale.nix ./tailscale.nix ]
    ++ homeManager;
}
