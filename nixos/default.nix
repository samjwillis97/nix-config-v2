{ super, config, lib, pkgs, flake, ... }:
let homeManager = if super.meta.useHomeManager then [ ./home.nix ] else [ ];
in {
  imports = [ ./meta.nix ./user.nix ./ssh.nix ./locale.nix ./tailscale.nix ]
    ++ homeManager;

  environment.systemPackages = with pkgs; [ vim git wget ];
}
