{ config, lib, pkgs, ... }: {
  programs.autorandr.profiles = {
    "primary" = {
      fingerprint = {
        Virtual1 = "--CONNECTED-BUT-EDID-UNAVAILABLE--Virtual1";
      };
      config = {
        Virtual1 = {
          enable = true;
          primary = true;
          position = "0x0";
          mode = "1920x1080";
          rate = "59.96";
        };
      };
    };
  };
}
