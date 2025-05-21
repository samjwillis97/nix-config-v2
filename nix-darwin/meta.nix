{ pkgs, flake, ... }:
{
  ids.gids.nixbld = 350;

  environment.systemPackages = with pkgs; [
    # cachix # FIXME idk if needed, pipeline might throw fit
  ];
  nix = import ../shared/nix.nix { inherit pkgs flake; } // {
    linux-builder.enable = false; # FIXME was breaking tings
  };

  # FIXME: What was this migrated to?
  # system.activationScripts.postUserActivation.text = ''
  #   # Following line should allow us to avoid a logout/login cycle
  #   /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  # '';
}
