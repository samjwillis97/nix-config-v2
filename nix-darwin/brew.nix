{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
    };

    brews = [
      "mas"
    ];

    casks = [
      "raycast"
      "slack"
      "discord"
      "spotify"
      "insomnia"
      "rectangle"
      "1password"
      "displaylink"
      # "figma" # work only
      "amethyst"
      "betterdisplay"
      "aldente"
    ];

    # These need to be purchased/owned by the logged in account before mas can install them
    masApps = { 
      # "Microsoft Remote Desktop" = 1295203466;
      # "Tailscale" = 1475387142;
      # "Xcode" = 497799835;
      # "1Password for Safari" = 1569813296;
    };
  };
}
