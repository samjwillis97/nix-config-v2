{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    libnotify
  ];

  services.swaync = {
    enable = true;

    settings = {
      timeout = 10;
      transition-time = 200;

      keyboard-shortcuts = true;

      image-visibility = "when-available";

      positionX = "right";
      positionY = "top";

      layer = "overlay";

      layer-shell = true;
      cssPriority = "application";

      # control-center-layer = "top";
      # control-center-margin-top = 0;
      # control-center-margin-bottom = 0;
      # control-center-margin-right = 0;
      # control-center-margin-left = 0;
      control-center-width = 500;

      notification-icon-size = 64;
      notification-window-width = 300;
      # notification-2fa-action = true;
      # notification-inline-replies = false;
      # notification-body-image-height = 100;
      # notification-body-image-width = 200;
    };
  };
}
