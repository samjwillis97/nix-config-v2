{ config, lib, pkgs, ... }:

{
  # Select internationalisation properties.
  i18n = { defaultLocale = lib.mkDefault "en_US.UTF-8"; };

  # Set your time zone.
  time.timeZone = lib.mkDefault "Australia/Sydney";
}
