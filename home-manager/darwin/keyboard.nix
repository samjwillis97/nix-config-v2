{lib, ...}: {
  #Disables most hotkeys
  home.activation.disableHotkeys = let
    hotkeys = [
      10
      11
      118
      12
      13
      15
      16
      160
      162
      163
      17
      175
      179
      18
      19
      190
      20
      21
      22
      222
      23
      24
      25
      26
      27
      32
      33
      34
      35
      36
      37
      52
      57
      59
      60
      61
      65
      7
      79
      8
      80
      81
      82
      9
      98
    ];
    disables = map (key:
      "defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add ${
        toString key
      } '<dict><key>enabled</key><false/></dict>'") hotkeys;
  in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Disable hotkeys
    echo >&2 "hotkey suppression..."
    set -e
    ${lib.concatStringsSep "\n" disables}
  '';
}
