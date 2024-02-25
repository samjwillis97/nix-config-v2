{ super, pkgs, lib, flake, ... }:
let inherit (flake) inputs;
in {
  imports = [ ./hardware-configuration.nix ../../nixos ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  systemd.tmpfiles.rules = map (vmHost:
    let
      machineId = builtins.hashString "md5" vmHost;
    in
      # creates a symlink of each MicroVM's journal under the host's /var/log/journal
      "L+ /var/log/journal/${machineId} - - - - /var/lib/microvms/${vmHost}/journal/${machineId}"
  ) ([ "first-microvm" ]);

  home-manager.users.${super.meta.username}.theme.wallpaper.path =
    pkgs.wallpapers.nixos-catppuccin-magenta-blue;
}
