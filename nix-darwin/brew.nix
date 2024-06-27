{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
    };

    brews = [ 
      "mas"
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
