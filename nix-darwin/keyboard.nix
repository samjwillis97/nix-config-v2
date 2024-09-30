{ lib, ... }:
{
  system.defaults.NSGlobalDomain = {
    # disable press-and-hold for keys in favor of key repeat
    ApplePressAndHoldEnabled = false;

    # set a fast though still usable key repeat rate
    InitialKeyRepeat = 20;
    KeyRepeat = 1;

    # enable full keyboard access for all controls (e.g. enable TAB in modal dialogs)
    AppleKeyboardUIMode = 3;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
    swapLeftCommandAndLeftAlt = false;
    swapLeftCtrlAndFn = true;
  };

  system.activationScripts.extraUserActivation.enable = true;
  # system.activationScripts.extraUserActivation.text = let
  #   hotkeys = [
  #     10
  #     11
  #     118
  #     12
  #     13
  #     15
  #     16
  #     160
  #     162
  #     163
  #     17
  #     175
  #     179
  #     18
  #     19
  #     190
  #     20
  #     21
  #     22
  #     222
  #     23
  #     24
  #     25
  #     26
  #     27
  #     32
  #     33
  #     34
  #     35
  #     36
  #     37
  #     52
  #     57
  #     59
  #     60
  #     61
  #     65
  #     7
  #     79
  #     8
  #     80
  #     81
  #     82
  #     9
  #     98
  #   ];
  # in { };

  # disableHotKeyCommands = map (key: ''
  #   defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add ${
  #     toString key
  #   } '
  #   <dict>
  #     <key>enabled</key><false/>
  #     <key>value</key>
  #     <dict>
  #       <key>type</key><string>standard</string>
  #       <key>parameters</key>
  #       <array>
  #         <integer>65535</integer>
  #         <integer>65535</integer>
  #         <integer>0</integer>
  #       </array>
  #     </dict>
  #   </dict>''') hotkeys;
  # in ''
  # echo >&2 "configuring hotkeys..."

  # ${lib.concatStringsSep "\n" disableHotKeyCommands}
  # '';
}
