{
  super,
  pkgs,
  lib,
  flake,
  ...
}:
let
  inherit (flake) inputs;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../nixos
    ../../modules/monitoring/exporters
    ../../modules/monitoring/promtail
  ];

  modules.monitoring = {
    promtail = {
      enable = false;
      lokiUrl = "http://insights:3100";
    };

    exporters.system.enable = false;
  };

  # Raise the soft open file descriptor limit for systemd user sessions.
  # Waybar and other desktop services require more than the default 1024.
  systemd.user.extraConfig = ''
    DefaultLimitNOFILE=524288
  '';

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  home-manager.users.${super.meta.username}.theme.wallpaper.path =
    pkgs.wallpapers.nixos-catppuccin-magenta-blue;
}
