{
  flake,
  pkgs,
  config,
  super,
  ...
}:
let
  inherit (super.meta) username;
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
    persistent-apps =
      [ "/Applications/Safari.app" ]
      ++ (
        if config.home-manager.users.${username}.programs.firefox.enable then
          [ "${pkgs.firefox-bin}/Applications/Firefox.app" ]
        else
          [ ]
      )
      ++ [
        "/system/Applications/Messages.app/"
        "/system/Applications/Mail.app"
        "/system/Applications/Calendar.app/"
        "/system/Applications/Notes.app/"
        "/system/Applications/Reminders.app/"
        "${pkgs.brewCasks.slack}/Applications/Slack.app"
        "${pkgs.brewCasks.discord}/Applications/Discord.app"
        "${config.home-manager.users.${username}.programs.wezterm.package}/Applications/WezTerm.app"
      ]
      ++ (
        if (builtins.elem pkgs.brewCasks.proxyman config.home-manager.users.${username}.home.packages) then
          [ "${pkgs.brewCasks.proxyman}/Applications/Proxyman.app" ]
        else
          [ ]
      )
      ++ [
        "/system/Applications/Music.app"
        "/system/Applications/iPhone Mirroring.app/"
        "/system/Applications/System Settings.app/"
      ];
    persistent-others = [ "${config.users.users.${username}.home}/Downloads" ];
  };
}
