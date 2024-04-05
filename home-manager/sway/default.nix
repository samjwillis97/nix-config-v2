{
  config,
  lib,
  pkgs,
  super,
  ...
}:
let
  # Aliases
  alt = "Mod4";
  modifier = "Mod1";

  commonOptions =
    let
      # Notification Daemon
      makoctl = "";
      screenShotName =
        with config.xdg.userDirs;
        "${pictures}/$(${pkgs.coreutils}/bin/date +%Y-%m-%d_%H-%M-%S)-screenshot.png";
    in
    import ../i3/common.nix rec {
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
      terminal = "${pkgs.alacritty}/bin/alacritty";

      # Screenshots
      fullScreenShot = ''
        ${pkgs.maim}/bin/maim -u "${screenShotName}" && \
        ${pkgs.libnotify}/bin/notify-send -u normal -t 5000 'Full screenshot taken'
      '';
      areaScreenShot = ''
        ${pkgs.maim}/bin/maim -u -s "${screenShotName}" && \
        ${pkgs.libnotify}/bin/notify-send -u normal -t 5000 'Area screenshot taken'
      '';

      extraBindings = {
        # "${modifier}+Tab" = "exec rofi -show window -modi window";
        "Ctrl+space" = "exec ${makoctl} close";
        "Ctrl+Shift+space" = "exec ${makoctl} close-all";
      };

      extraConfig = ''
        hide_edge_borders --i3 smart

        # XCURSOR_SIZE - I Do feel like this is not going to work, what the fuck is name?
        # TODO: Get this name somehow 
        seat seat0 xcursor_theme Adwaita 24
      '';
    };
in
{
  imports = [
    ../i3/gammastep.nix
    ../i3/i3status-rust.nix
    ./wofi.nix
    ./mako.nix
    # TODO: Rofi + Dunst equivalent
  ];

  home.packages = with pkgs; [
    mako
    dex
    swayidle
    swaylock
    wl-clipboard
    wdisplays
  ];

  # I feel like i could definitely move this into another file - anyway
  wayland.windowManager.sway = with commonOptions; {
    enable = true;

    inherit extraConfig;

    config = commonOptions.config // {
      startup = [
        { command = "${pkgs.dex}/bin/dex --autostart"; }
        {
          command =
            let
              swayidle = "${pkgs.swayidle}/bin/swayidle";
              swaylock = "${pkgs.swaylock}/bin/swaylock";
              swaymsg = "${pkgs.sway}/bin/swaymsg";
            in
            ''
              ${swayidle} -w \
              timeout 600 '${swaylock} -f -c 000000' \
              timeout 605 '${swaymsg} "output * dpms off"' \
              resume '${swaymsg} "output * dpms on"' \
              before-sleep '${swaylock} -f -c 000000' \
              lock '${swaylock} -f -c 000000'
            '';
        }
      ];

      input = {
        "type:keyboard" = {
          xkb_layout = "us";
          xkb_options = "caps:escape";
        };
        "type:pointer" = {
          accel_profile = "flat";
        };
        "type:touchpad" = {
          drag = "enabled";
          drag_lock = "enabled";
          middle_emulation = "enabled";
          natural_scroll = "enabled";
          scroll_method = "two_finger";
          tap = "enabled";
          tap_button_map = "lmr";
        };
      };

      output = {
        "*" = {
          # DPI
          scale = "1";
        };
      };
    };

    extraSessionCommands = ''
      export XDG_CURRENT_DESKTOP=sway
      # Breaks Chromium/Electron
      # export GDK_BACKEND=wayland
      # Firefox
      export MOZ_ENABLE_WAYLAND=1
      # Qt
      export XDG_SESSION_TYPE=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      # SDL
      export SDL_VIDEODRIVER=wayland
      # Elementary/EFL
      export ECORE_EVAS_ENGINE=wayland_egl
      export ELM_ENGINE=wayland_egl
      # Fix for some Java AWT applications (e.g. Android Studio),
      # use this if they aren't displayed properly:
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';

    systemdIntegration = true;

    wrapperFeatures = {
      base = true;
      gtk = true;
    };

    extraOptions =
      let
        videoDrivers = super.services.xserver.videoDrivers or [ ];
      in
      # If nvidia is in the videoDrivers array add this flag
      lib.optionals (builtins.elem "nvidia" videoDrivers) [ "--unsupported-gpu" ];
  };
}
