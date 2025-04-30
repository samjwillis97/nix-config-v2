{
  config,
  lib,
  pkgs,
  ...
}:
let
  xsession = "${config.home.homeDirectory}/.xsession";
in
{
  # Compatibility with xinit/sx
  home.file.".xinitrc".source = config.lib.file.mkOutOfStoreSymlink xsession;
  xdg.configFile."sx/sxrc".source = config.lib.file.mkOutOfStoreSymlink xsession;

  systemd.user.services = {
    xss-lock = {
      Unit = {
        Description = "Use external locker as X screen saver";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service =
        let
          lockscreen = pkgs.writeShellScriptBin "lock-screen" ''
            export XSECURELOCK_FORCE_GRAB=2
            export XSECURELOCK_BLANK_DPMS_STATE="off"
            export XSECURELOCK_DATETIME_FORMAT="%H:%M:%S - %a %d/%m"
            export XSECURELOCK_SHOW_DATETIME=1
            export XSECURELOCK_SHOW_HOSTNAME=0
            export XSECURELOCK_SHOW_USERNAME=0
            export XSECURELOCK_FONT="FiraCode Nerd Font Mono:style=Regular"

            exec ${pkgs.xsecurelock}/bin/xsecurelock $@
          '';
          notify = pkgs.writeShellScriptBin "notify" ''
            ${pkgs.libnotify}/bin/notify-send -t 30 "30 seconds to lock"
          '';
        in
        {
          ExecStart = lib.concatStringsSep " " [
            "${pkgs.xss-lock}/bin/xss-lock"
            "--notifier ${notify}/bin/notify"
            "--transfer-sleep-lock"
            "--session $XDG_SESSION_ID"
            "--"
            "${lockscreen}/bin/lock-screen"
          ];
        };
    };
    wallpaper = {
      Unit = {
        Description = "Set wallpaper";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = lib.concatStringsSep " " [
          "${pkgs.feh}/bin/feh"
          "--no-fehbg"
          "--bg-${config.theme.wallpaper.scale}"
          "${config.theme.wallpaper.path}"
        ];
        Type = "oneshot";
      };
    };
  };

  xresources.properties = {
    "Xft.dpi" = "96";
  };

  xsession = {
    enable = true;
    numlock.enable = true;
    initExtra =
      # Automatically loads the best layout from autorandr
      ''
        ${pkgs.autorandr}/bin/autorandr --change
        xset r rate 250 50
      '';
  };
}
