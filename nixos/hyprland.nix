{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Enable PAM integration necessary for e.g.: swaylock
  security.pam.services.hyprlock = { };

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1"; # enables electron apps to run native
  };

  programs = {
    dconf.enable = true;
    light.enable = true;
  };

  services.libinput = {
    enable = true;
    mouse = {
      accelProfile = "flat";
      accelSpeed = null;
    };
  };

  programs.hyprland = {
    enable = true;

    withUWSM = true;

    xwayland.enable = true;

  };

  xdg.portal = {
    enable = true;

    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  programs.regreet.enable = true;
}
