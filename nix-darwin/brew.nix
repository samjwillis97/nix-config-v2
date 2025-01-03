{ super, flake, ... }:
let
  inherit (super.meta) username;
in
{
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
    autoMigrate = true;

    taps = {
      "homebrew/homebrew-core" = flake.inputs.homebrew-core;
      "homebrew/homebrew-cask" = flake.inputs.homebrew-cask;
    };

  };

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
    };

    brews = [ ];

    # If struggling to install one of these
    # try updating brew manually on machine.
    casks = [
      # "orbstack"
      # "1password"
      "appcleaner"
      "raycast"
      "displaylink"
      "betterdisplay"
      "disk-inventory-x"
      "ghostty"
      # "proxyman"
      # "logi-options-plus"
    ];

    # These need to be purchased/owned by the logged in account before mas can install them
    masApps = { };
  };
}
