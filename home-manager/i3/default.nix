# Config by: https://github.com/thiagokokada/nix-configs/blob/master/home-manager/i3/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Aliases
  alt = "Mod4";
  modifier = "Mod1";

  commonOptions =
    let
      dunstctl = "${pkgs.dunst}/bin/dunstctl";

      screenShotName =
        with config.xdg.userDirs;
        "${pictures}/$(${pkgs.coreutils}/bin/date +%Y-%m-%d_%H-%M-%S)-screenshot.png";

      toggleMuteScript = pkgs.writeShellApplication {
        name = "toggleMute.sh"; # this will be the name of the binary
        runtimeInputs = [ pkgs.wireplumber pkgs.libnotify pkgs.gnugrep ]; # Dependencies go here
        # Note that no shebang is necessary, writeShellApplication will prepend
        # it.
        #
        # Also note that there is no need to reference the package, the
        # runtimeInputs will take care of adding `bin` directory to this script's
        # path
        text = ''
          wpctl set-mute @DEFAULT_SOURCE@ toggle && \
          if wpctl get-volume @DEFAULT_SOURCE@ | grep -q "\\[MUTED\\]"; then \
            notify-send -u critical -t 5000 --replace-id=432 'Microphone: OFF'; \
          else \
            notify-send -u critical -t 5000 --replace-id=432 'Microphone: ON'; \
          fi
        '';
      };
    in
    import ./common.nix rec {
      inherit
        config
        lib
        modifier
        alt
        ;

      browser = "firefox";
      fileManager = "${terminal} ${pkgs.nnn}/bin/nnn -a -P p";
      statusCommand =
        with config;
        "${programs.i3status-rust.package}/bin/i3status-rs ${xdg.configHome}/i3status-rust/config-i3.toml";
      menu = "rofi -show drun";
      # light needs to be installed in system, so not defining a path here
      light = "light";
      pamixer = "${pkgs.pamixer}/bin/pamixer";
      playerctl = "${pkgs.playerctl}/bin/playerctl";
      terminal = "${pkgs.wezterm}/bin/wezterm";

      # Screenshots
      fullScreenShot = ''
        ${pkgs.maim}/bin/maim -u "${screenShotName}" && \
        ${pkgs.libnotify}/bin/notify-send -u normal -t 5000 'Full screenshot taken'
      '';
      areaScreenShot = ''
        ${pkgs.maim}/bin/maim -u -s "${screenShotName}" && \
        ${pkgs.libnotify}/bin/notify-send -u normal -t 5000 'Area screenshot taken'
      '';

      toggleMute = lib.getExe toggleMuteScript;

      extraBindings = {
        "${modifier}+Tab" = "exec rofi -show window -modi window";
        "Ctrl+space" = "exec ${dunstctl} close";
        "Ctrl+Shift+space" = "exec ${dunstctl} close-all";
      };

      extraConfig = ''
        # app specific fixes
        # https://github.com/ValveSoftware/steam-for-linux/issues/1040
        for_window [class="^Steam$" title="^Friends$"] floating enable
        for_window [class="^Steam$" title="Steam - News"] floating enable
        for_window [class="^Steam$" title=".* - Chat"] floating enable
        for_window [class="^Steam$" title="^Settings$"] floating enable
        for_window [class="^Steam$" title=".* - event started"] floating enable
        for_window [class="^Steam$" title=".* CD key"] floating enable
        for_window [class="^Steam$" title="^Steam - Self Updater$"] floating enable
        for_window [class="^Steam$" title="^Screenshot Uploader$"] floating enable
        for_window [class="^Steam$" title="^Steam Guard - Computer Authorization Required$"] floating enable
        for_window [title="^Steam Keyboard$"] floating enable

        for_window [window_role="pop-up"] floating enable
        for_window [window_role="task_dialog"] floating enable
        for_window [title="Settings"] floating enable
        for_window [window_role="PictureInPicture"] floating enable
        for_window [window_role="PictureInPicture"] sticky enable
        for_window [class="Plexamp"] floating enable
        for_window [class="Plexamp"] sticky enable
        for_window [title="splash"] floating enable
        for_window [title="searcher"] floating enable
      '';
    };
in
{
  # TODO: nnn
  imports = [
    ./rofi.nix
    ./i3status-rust.nix
    ./x11.nix
    ./dunst.nix
    ./picom.nix
    ./gammastep.nix
    ../autorandr
  ];

  home = {
    packages = with pkgs; [
      feh
      ffmpegthumbnailer # Just a thumbnailer
      libnotify
      flameshot
      maim # This is a screenshotter - flameshot replacement - TODO: Replace with flameshot
      playerctl # Some sort of media player
      wmctrl # Window manager control?
      xsecurelock
      xss-lock
      pamixer
      nnn
      arandr
      dex
    ];
  };

  xsession.windowManager.i3 = with commonOptions; {
    enable = true;

    package = pkgs.i3-gaps;
    inherit extraConfig;

    config = commonOptions.config // {
      startup = [
        {
          command = "${pkgs.dex}/bin/dex --autostart";
          notification = false;
        }
      ];
    };
  };
}
