{ super, pkgs, ... }:
{
  imports = [
    ../modules/networking
    ./meta.nix
    ./user.nix
    ./ssh.nix
    ./locale.nix
    ./tailscale.nix
    ./theming.nix
  ];

  modules.networking.mdns.enable = true;

  networking.hostName = super.meta.hostname;
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    agenix
  ];
}
