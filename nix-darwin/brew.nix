{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
    };

    taps = [
      "FelixKratz/formulae"
    ];

    brews = [ 
      "mas"
      "FelixKratz/formulae/borders"
    ];

    # If struggling to install one of these
    # try updating brew manually on machine.
    casks = [
      "orbstack"
      "raycast"
      "slack"
      "discord"
      "1password"
      "displaylink"
      "betterdisplay"
      "logi-options-plus"
      "appcleaner"
    ];

    # These need to be purchased/owned by the logged in account before mas can install them
    masApps = { };
  };
}
