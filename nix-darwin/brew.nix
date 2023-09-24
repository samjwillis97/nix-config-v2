{
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
    };

    brews = [];

    casks = ["raycast" "zoom" "rectangle" "1password"];

    masApps = { 
      "Microsoft Remote Desktop" = 1295203466;
      "Tailscale" = 1475387142;
      "Xcode" = 497799835;
    };
  };
}
