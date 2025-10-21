{
  pkgs,
  config,
  lib,
  ...
}:
let
  package = config.services.sketchybar.package;

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
    sketchybar --set "$NAME" label="$(date '+%d/%m %H:%M')"
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
      # This is a demo config to showcase some of the most important commands.
      # It is meant to be changed and configured, as it is intentionally kept sparse.
      # For a (much) more advanced configuration example see my dotfiles:
      # https://github.com/FelixKratz/dotfiles
      source ${pkgs.sketchybar-app-font}/bin/icon_map.sh

      # PLUGIN_DIR="$CONFIG_DIR/plugins"

      ##### Bar Appearance #####
      # Configuring the general appearance of the barf      # These are only some of the options available. For all options see:
      # https://felixkratz.github.io/SketchyBar/config/bar
      # If you are looking for other colors, see the color picker:
      # https://felixkratz.github.io/SketchyBar/config/tricks#color-picker

      ${package}/bin/sketchybar --bar position=top height=40 blur_radius=30 color=0x40000000

      ##### Changing Defaults #####
      # We now change some default values, which are applied to all further items.
      # For a full list of all available item properties see:
      # https://felixkratz.github.io/SketchyBar/config/items

      default=(
        label.font="SF Pro Rounded"
        padding_left=10
        padding_right=10
        icon.color=0xffffffff
        label.color=0xffffffff
        icon.padding_left=4
        icon.padding_right=4
        label.padding_left=4
        label.padding_right=4
      )
      ${package}/bin/sketchybar --default "''${default[@]}"

      ##### Adding Mission Control Space Indicators #####
      # Let's add some mission control spaces:
      # https://felixkratz.github.io/SketchyBar/config/components#space----associate-mission-control-spaces-with-an-item
      # to indicate active and available mission control spaces.

      SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9")
      for i in "''${!SPACE_ICONS[@]}"
      do
        sid="$(($i+1))"
        space=(
          space="$sid"
          icon="''${SPACE_ICONS[i]}"
          icon.padding_left=7
          icon.padding_right=7
          background.color=0x40ffffff
          background.corner_radius=5
          background.height=25
          label.drawing=off
          script="${lib.getExe spaceScript}"
          click_script="yabai -m space --focus $sid"
        )
        ${package}/bin/sketchybar --add space space."$sid" left --set space."$sid" "''${space[@]}"
      done

      ##### Adding Left Items #####
      # We add some regular items to the left side of the bar, where
      # only the properties deviating from the current defaults need to be set

      ${package}/bin/sketchybar --add item chevron left \
                 --set chevron icon= label.drawing=off \
                 --add item front_app left \
                 --set front_app icon.drawing=off script="$PLUGIN_DIR/front_app.sh" \
                 --subscribe front_app front_app_switched

      ##### Adding Right Items #####
      # In the same way as the left items we can add items to the right side.
      # Additional position (e.g. center) are available, see:
      # https://felixkratz.github.io/SketchyBar/config/items#adding-items-to-sketchybar

      # Some items refresh on a fixed cycle, e.g. the clock runs its script once
      # every 10s. Other items respond to events they subscribe to, e.g. the
      # volume.sh script is only executed once an actual change in system audio
      # volume is registered. More info about the event system can be found here:
      # https://felixkratz.github.io/SketchyBar/config/events

      ${package}/bin/sketchybar --add item clock right \
                 --set clock update_freq=10 icon=  script="${lib.getExe clockScript}" \
                 --add item volume right \
                 --set volume script="$PLUGIN_DIR/volume.sh" \
                 --subscribe volume volume_change \
                 --add item battery right \
                 --set battery update_freq=120 script="${lib.getExe batteryScript}" \
                 --subscribe battery system_woke power_source_change

      ##### Force all scripts to run the first time (never do this in a script) #####
      ${package}/bin/sketchybar --update
    '';
  };
}
