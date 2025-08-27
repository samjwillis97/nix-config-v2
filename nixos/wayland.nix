{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enable PAM integration necessary for e.g.: swaylock
  security.pam.services.hyprlock = {};

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1"; # enables electron apps to run native
  };

  # TODO: required?
  # Force kernel log in tty1, otherwise it will override greetd
  boot.kernelParams = [ "console=tty1" ];

  # TODO: Here?
  # Configure special programs (i.e. hardware access)
  programs = {
    dconf.enable = true;
    light.enable = true;
  };

  services = {
    # TODO: Here - idk if needed?
    # Enable libinput
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
      };
      mouse = {
        accelProfile = "flat";
        accelSpeed = null;
      };
    };

    # Configure greetd, a lightweight session manager
    greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd hyprland";
          user = "greeter";
        };
        default_session = initial_session;
      };
    };
  };
}
