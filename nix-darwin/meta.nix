{ pkgs, flake, ... }:
{
  environment.systemPackages = with pkgs; [ cachix ];
  services.nix-daemon.enable = true;
  nix = import ../shared/nix.nix { inherit pkgs flake; };

  system.activationScripts.postUserActivation.text = ''
    # Following line should allow us to avoid a logout/login cycle
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
