{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
    };

    brews = [ ];

    # If struggling to install one of these
    # try updating brew manually on machine.
    casks = [
      "orbstack"
      "1password"
      "displaylink"
      "logi-options-plus"
    ];

    # These need to be purchased/owned by the logged in account before mas can install them
    masApps = { };
  };
}
