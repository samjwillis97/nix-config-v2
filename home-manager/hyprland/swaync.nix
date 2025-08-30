{ pkgs, ... }:
{
  home.packages = with pkgs; [
    libnotify
  ];

  services.swaync = {
    enable = true;

    settings = {
      timeout = 10;
      transition-time = 200;

      keyboard-shortcutes = true;

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

    style = ''
    * {
      font-family: "Fire Sans", sans-serif;
      font-size: 14px;
    }

    .notification {
      background-color: #222222;
      border-radius: 10px;
      color: #ffffff;
      border: 1px solid #444444;
    }

    .control-center {
      background-color: #333333;
      border-radius: 10px;
      color: #ffffff;
    }
    '';
  };
}
