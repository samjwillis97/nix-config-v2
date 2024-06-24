{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
    };

    brews = [ "mas" ];

    # If struggling to install one of these
    # try updating brew manually on machine.
    casks = [
      "orbstack"
      "raycast"
      "slack"
      "discord"
      "spotify"
      "1password"
      "displaylink"
      "betterdisplay"
      "logi-options-plus"
      "appcleaner"
      "nikitabobko/tap/aerospace"
    ];

    # These need to be purchased/owned by the logged in account before mas can install them
    masApps = {
    };
  };
}
