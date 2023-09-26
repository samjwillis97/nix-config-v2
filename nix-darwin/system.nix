{ config, lib, pkgs, ... }:
{
    system = {
        keyboard = {
            enableKeyMapping = true;
            remapCapsLockToEscape = true;
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
