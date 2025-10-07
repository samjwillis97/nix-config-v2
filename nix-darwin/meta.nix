{
  pkgs,
  flake,
  super,
  ...
}:
let
  inherit (super.meta) nixbldGid;
in
{
  ids.gids.nixbld = nixbldGid;

  nix = import ../shared/nix.nix { inherit pkgs flake; } // {
    linux-builder.enable = true; # FIXME was breaking tings
  };

  # FIXME: What was this migrated to?
  # system.activationScripts.postUserActivation.text = ''
  #   # Following line should allow us to avoid a logout/login cycle
  #   /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  # '';
}
