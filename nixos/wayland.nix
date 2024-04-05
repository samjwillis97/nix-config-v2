{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enable PAM integration necessary for e.g.: swaylock
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };
}
