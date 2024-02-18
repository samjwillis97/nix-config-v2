{ config, lib, pkgs, ... }:
{
    system = {
        defaults.CustomSystemPreferences = {
          # Do not write .DS_Store files outside macOS
          "com.apple.desktopservices" = {
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
          # Disable mouse acceleration
          # "com.apple.mouse.scaling" = -1;
        };
    };
    defaults.CustomSystemPreferences = {
      # Do not write .DS_Store files outside macOS
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      # Disable mouse acceleration
      # "com.apple.mouse.scaling" = -1;
    };
  };
}
