{ config, lib, pkgs, ... }:

{
  # Select internationalisation properties.
  i18n = {
    defaultLocale = lib.mkDefault "en_US.UTF-8";
  };

  # Set X11 keyboard layout.
  services.xserver = {
    layout = lib.mkDefault "us";
    # Remap Caps Lock to Esc, and use Super+Space to change layouts
    xkbOptions = lib.mkDefault "caps:escape";
  };

  # Set your time zone.
  time.timeZone = lib.mkDefault "Australia/Sydney";
}
