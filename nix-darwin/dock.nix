{
  pkgs,
  config,
  super,
  lib,
  ...
}:
let
  inherit (super.meta) username;
  firefoxEnabled = config.home-manager.users.${username}.programs.firefox.enable;
  workEnabled = config.home-manager.users.${username}.modules.darwin.work;
in
{
  system.defaults.dock = {
    enable-spring-load-actions-on-all-items = true;
    appswitcher-all-displays = true;
    autohide = false;
    dashboard-in-overlay = false;
    expose-group-by-app = true;
    launchanim = true;
    minimize-to-application = false;
    mru-spaces = false;
    orientation = "bottom";
    show-process-indicators = true;
    show-recents = false;
    showhidden = false;
    static-only = false;
    tilesize = 48;
    magnification = false;
    largesize = 56;
    persistent-apps = builtins.filter (a: a != "") ([
      "/Applications/Safari.app/"
      (lib.optionalString firefoxEnabled "${pkgs.firefox-bin}/Applications/Firefox.app")
      "/system/Applications/Messages.app/"
      "/system/Applications/Mail.app"
      "/system/Applications/Calendar.app/"
      "/system/Applications/Notes.app/"
      "/system/Applications/Reminders.app/"
      "${pkgs.slack}/Applications/Slack.app"
      # (lib.optionalString workEnabled "${pkgs.brewCasks.workplace-chat}/Applications/Workplace Chat.app")
      "${pkgs.zoom-us}/Applications/zoom.us.app"
      "${pkgs.discord}/Applications/Discord.app"
      "${config.home-manager.users.${username}.programs.wezterm.package}/Applications/WezTerm.app"
      (lib.optionalString workEnabled "${pkgs.brewCasks.proxyman}/Applications/Proxyman.app")
      "/system/Applications/Music.app"
      "/system/Applications/iPhone Mirroring.app/"
      "/Applications/1Password.app"
      "/system/Applications/System Settings.app/"
    ]);
    persistent-others = [ "${config.users.users.${username}.home}/Downloads" ];
  };
}
