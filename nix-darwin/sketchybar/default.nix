{
  pkgs,
  config,
  lib,
  ...
}:
let
  package = config.services.sketchybar.package;

  sketchyBarExe = lib.getExe package;

  spaceScript = pkgs.writeShellScriptBin "space" ''
    # The $SELECTED variable is available for space components and indicates if
    # the space invoking this script (with name: $NAME) is currently selected:
    # https://felixkratz.github.io/SketchyBar/config/components#space----associa...

    ${pkgs.sketchybar}/bin/sketchybar --set "$NAME" background.drawing="$SELECTED"
  '';

  batteryScript = pkgs.writeShellScriptBin "battery" ''
    PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
    CHARGING="$(pmset -g batt | grep 'AC Power')"

    if [ "$PERCENTAGE" = "" ]; then
      exit 0
    fi

    case "''${PERCENTAGE}" in
      9[0-9]|100) ICON=""
      ;;
      [6-8][0-9]) ICON=""
      ;;
      [3-5][0-9]) ICON=""
      ;;
      [1-2][0-9]) ICON=""
      ;;
      *) ICON=""
    esac

    if [[ "$CHARGING" != "" ]]; then
      ICON=""
    fi

    # The item invoking this script (name $NAME) will get its icon and label
    # updated with the current battery status
    sketchybar --set "$NAME" icon="$ICON" label="''${PERCENTAGE}%"
  '';

  clockScript = pkgs.writeShellScriptBin "clock" ''
    COLOR_DEFAULT="0xffdddddd"

    HOUR=$(date '+%H')
    ${sketchyBarExe} --set $NAME label="$(date '+%a %I:%M %p')" label.color=$COLOR_DEFAULT
  '';
in
{
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  environment.systemPackages = with pkgs; [
    sketchybar-app-font
  ];

  services.sketchybar = {
    enable = true;

    config = ''
      COLOR_DEFAULT="0xffdddddd"
      COLOR_BACKGROUND="0xe01d2021"

      ICON_APPLE=􀣺
      ICONS_SPACE=(󰬺 󰬻 󰬼 󰬽 󰬾 󰬿 󰭀 󰭁 󰭂)

      default=(
        label.font.family="SF Pro Roudned"
        label.font.size=12
        label.padding_left=10
        label.padding_right=10
        label.align=center
        icon.padding_left=16
        icon.padding_right=16
        icon.font.size=14
      )

      blur_background=(
        background.drawing=on
        blur_radius=24
        background.height=36
        background.corner_radius=10
        background.color=""
      )

      ${sketchyBarExe} --bar color=0x00000000 \
        height=40 \
        margin=5 \
        y_offset=5 \
        padding_left=8 \
        padding_right=0 \
        sticky=on \
        topmost=window

      ${sketchyBarExe} --default padding_left=8 \
        padding_right=4 \
        background.border_color=$COLOR_DEFAULT \
        background.border_width=0 \
        background.height=24                             \
        background.corner_radius=5 \
        icon.color=$COLOR_DEFAULT                        \
        icon.highlight_color=$COLOR_BACKGROUND           \
        icon.padding_left=6 icon.padding_right=2         \
        icon.font="Nerd Font:Regular:16.0"               \
        label.color=$COLOR_DEFAULT                       \
        label.highlight_color=$COLOR_BACKGROUND          \
        label.padding_left=2 label.padding_right=6       \
        label.font="SF Pro Rounded"                      \
        label.font.size=12.0

      ${sketchyBarExe} --add event window_change \
        --add event window_focus \
        --add event title_change

      ${sketchyBarExe} --add item apple left \
        --set apple background.border_width=0 background.height=24 icon=$ICON_APPLE  click_script="./bin/menus -s 0"  \
        --subscribe apple mouse.clicked \
        --add bracket button apple \
        --set button background.color=0x5ddddddd background.border_color=$COLOR_DEFAULT \
        --add item sep.l1 left \
        --set sep.l1 padding_left=4 padding_right=4 background.drawing=off icon.drawing=off label.drawing=off

      LENGTH=''${#ICONS_SPACE[@]}
      for i in "''${!ICONS_SPACE[@]}"
      do
        sid=$((i+1))
        PAD_LEFT=2
        PAD_RIGHT=8
        if [[ $i == 0 ]]; then
          PAD_LEFT=8
        elif [[ $i == $((LENGTH-1)) ]]; then
          PAD_RIGHT=8
        fi
        # ${sketchyBarExe} --add space space.$sid left \
        #   --set space.$sid script="$PLUGIN_DIR/app_space.sh" associated_space=$sid padding_left=$PAD_LEFT padding_right=$PAD_RIGHT background.color=$COLOR_DEFAULT background.border_width=0 background.corner_radius=6 background.height=24 icon="''${ICONS_SPACE[$i]}" \
        #   --subscribe space.$sid front_app_switched window_change
      done

      ${sketchyBarExe} --add bracket spaces '/space\..*/' \
        --set spaces background.color=0x5ddddddd

      ${sketchyBarExe} --add item sep.r1 right \
        --set sep.r1 padding_left=4 padding_right=4 background.drawing=off icon.drawing=off label.drawing=off

      ${sketchyBarExe} --add item time right \
        --set time script="${lib.getExe clockScript}" update_freq=5 padding_left=6 padding_right=8 background.border_width=0 background.corner_radius=6 background.height=24 click_script="osascript -e 'tell application \"System Events\" to click menu bar item 1 of menu bar 1 of application process \"ControlCenter\"'" \
        --add bracket clock time \
        --set clock background.color=0x5ddddddd background.border_color=$COLOR_DEFAULT \
        --add item sep.r3 right \
        --set sep.r3 padding_left=4 padding_right=4 background.drawing=off icon.drawing=off label.drawing=off

      # ${sketchyBarExe} --add item centre right \
      #   --set centre icon.color=$COLOR_DEFAULT icon=$ICON_CMD padding_left=0 padding_right=4 background.border_width=0 background.corner_radius=6 background.height=24 click_script="osascript -e 'tell application \"System Events\" to click menu bar item 2 of menu bar 1 of application process \"ControlCenter\"'" \
      #   --add item wifi right \
      #   --set wifi script="$PLUGIN_DIR/wifi.sh" update_freq=5 padding_left=0 padding_right=0 background.border_width=0 background.corner_radius=6 background.height=24 \
      #   --subscribe wifi wifi_change \
      #   --add item yabai_mode right \
      #   --set yabai_mode padding_left=4 padding_right=4 update_freq=1 script="$PLUGIN_DIR/yabai.sh" click_script="$PLUGIN_DIR/yabai_click.sh" \
      #   --subscribe yabai_mode mouse.clicked window_focus front_app_switched space_change title_change \
      #   --add bracket status centre yabai_mode wifi \
      #   --set status background.color=0x5ddddddd background.border_color=$COLOR_DEFAULT \
      #   --add item seperator.r5 right \
      #   --set seperator.r5 padding_left=4 padding_right=4 background.drawing=off icon.drawing=off label.drawing=off

      ${sketchyBarExe} --hotload true
      ${sketchyBarExe} --update
    '';

    # config = ''
    #   # This is a demo config to showcase some of the most important commands.
    #   # It is meant to be changed and configured, as it is intentionally kept sparse.
    #   # For a (much) more advanced configuration example see my dotfiles:
    #   # https://github.com/FelixKratz/dotfiles
    #   source ${pkgs.sketchybar-app-font}/bin/icon_map.sh
    #
    #   # PLUGIN_DIR="$CONFIG_DIR/plugins"
    #
    #   ##### Bar Appearance #####
    #   # Configuring the general appearance of the barf      # These are only some of the options available. For all options see:
    #   # https://felixkratz.github.io/SketchyBar/config/bar
    #   # If you are looking for other colors, see the color picker:
    #   # https://felixkratz.github.io/SketchyBar/config/tricks#color-picker
    #
    #   ${package}/bin/sketchybar --bar position=top height=40 blur_radius=30 color=0x40000000
    #
    #   ##### Changing Defaults #####
    #   # We now change some default values, which are applied to all further items.
    #   # For a full list of all available item properties see:
    #   # https://felixkratz.github.io/SketchyBar/config/items
    #
    #   default=(
    #     padding_left=5
    #     padding_right=5
    #     icon.font="FiraCode Nerd Font:Bold:17.0"
    #     label.font="FiraCode Nerd Font:Bold:14.0"
    #     icon.color=0xffffffff
    #     label.color=0xffffffff
    #     icon.padding_left=4
    #     icon.padding_right=4
    #     label.padding_left=4
    #     label.padding_right=4
    #   )
    #   ${package}/bin/sketchybar --default "''${default[@]}"
    #
    #   ##### Adding Mission Control Space Indicators #####
    #   # Let's add some mission control spaces:
    #   # https://felixkratz.github.io/SketchyBar/config/components#space----associate-mission-control-spaces-with-an-item
    #   # to indicate active and available mission control spaces.
    #
    #   SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9")
    #   for i in "''${!SPACE_ICONS[@]}"
    #   do
    #     sid="$(($i+1))"
    #     space=(
    #       space="$sid"
    #       icon="''${SPACE_ICONS[i]}"
    #       icon.padding_left=7
    #       icon.padding_right=7
    #       background.color=0x40ffffff
    #       background.corner_radius=5
    #       background.height=25
    #       label.drawing=off
    #       script="${lib.getExe spaceScript}"
    #       click_script="yabai -m space --focus $sid"
    #     )
    #     ${package}/bin/sketchybar --add space space."$sid" left --set space."$sid" "''${space[@]}"
    #   done
    #
    #   ##### Adding Left Items #####
    #   # We add some regular items to the left side of the bar, where
    #   # only the properties deviating from the current defaults need to be set
    #
    #   ${package}/bin/sketchybar --add item chevron left \
    #              --set chevron icon= label.drawing=off \
    #              --add item front_app left \
    #              --set front_app icon.drawing=off script="$PLUGIN_DIR/front_app.sh" \
    #              --subscribe front_app front_app_switched
    #
    #   ##### Adding Right Items #####
    #   # In the same way as the left items we can add items to the right side.
    #   # Additional position (e.g. center) are available, see:
    #   # https://felixkratz.github.io/SketchyBar/config/items#adding-items-to-sketchybar
    #
    #   # Some items refresh on a fixed cycle, e.g. the clock runs its script once
    #   # every 10s. Other items respond to events they subscribe to, e.g. the
    #   # volume.sh script is only executed once an actual change in system audio
    #   # volume is registered. More info about the event system can be found here:
    #   # https://felixkratz.github.io/SketchyBar/config/events
    #
    #   ${package}/bin/sketchybar --add item clock right \
    #              --set clock update_freq=10 icon=  script="${lib.getExe clockScript}" \
    #              --add item volume right \
    #              --set volume script="$PLUGIN_DIR/volume.sh" \
    #              --subscribe volume volume_change \
    #              --add item battery right \
    #              --set battery update_freq=120 script="${lib.getExe batteryScript}" \
    #              --subscribe battery system_woke power_source_change
    #
    #   ##### Force all scripts to run the first time (never do this in a script) #####
    #   ${package}/bin/sketchybar --update
    # '';
  };
}
