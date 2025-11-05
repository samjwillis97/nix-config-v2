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

  space-handling = pkgs.writeShellScriptBin "space-handling" ''
    # This script would contain logic to manage spaces
    # For example, it could listen to space change events and update sketchybar accordingly
  '';
in
{
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  environment.systemPackages = with pkgs; [
    sketchybar-app-font
  ];

  services.sketchybar = {
    enable = true;

    config =
      let
        MenuBarItems = [
          "Control Centre,Battery"
          "Control Centre,Sound"
          "NetWorker Lite,network"
        ];

        buildMenuBarItem = (
          name: ''
            ${sketchyBarExe} \
              --add alias "${name}" right \
              --set "${name}" \
                alias.color="0xFFFFFFFF" \
                width=40 \
                padding_left=12 \
                padding_right=12 \
                icon.drawing=off \
                label.drawing=off
          ''
        );

        spacesCount = 10;
        spaceIndexes = map (v: toString v) (lib.range 1 spacesCount);
        buildSpaceItem = (
          index: ''
            ${sketchyBarExe} \
              --add space "space.${toString index}" left \
              --set "space.${toString index}" \
                icon.width=0 \
                label="${toString index}" \
                label.align=center \
                label.background.height=24 \
                label.background.corner_radius=5 \
                associated_space=${toString index}
                # TODO: Displays
                # TODO: Script
          ''
        );

      in
      ''
        source ${pkgs.sketchybar-app-font}/bin/icon_map.sh

        bar=(
          position=top
          color=0x00000000
          height=54
          padding_left=5
          padding_right=10
        )

        default=(
          label.font.family="SF Pro Rounded"
          label.padding_left=10
          label.padding_right=10
          label.align=center
          icon.padding_left=16
          icon.padding_right=16
          icon.font.size=14.0
        )

        blur_background=(
          background.drawing=on
          blur_radius=24
          background.height=36
          background.corner_radius=10
          background.color="0x20FFF7ED"
        )

        spacer=(
            label.drawing=off
            icon.drawing=off
        )

        # Default bar config
        ${sketchyBarExe} --bar "''${bar[@]}" --default "''${default[@]}"

        ## Adding items

        ## Apple System Menu
        ${sketchyBarExe} \
          --add item apple left \
          --set apple \
            display=1 \
            label="􀣺" \
            label.width=40 \
            icon.drawing=off

        # Spacer
        ${sketchyBarExe} \
          --add item spacer.1 left \
          --set spacer.1 \
            width=12 \
            "''${spacer[@]}"

        # Spacer
        ${sketchyBarExe} \
          --add item spacer.2 left \
          --set spacer.2 \
            width=12 \
            "''${spacer[@]}"

        # Spaces
        ${lib.strings.concatStringsSep "\n" (map buildSpaceItem spaceIndexes)}

        # Spacer
        ${sketchyBarExe} \
          --add item spacer.3 left \
          --set spacer.3 \
            width=12 \
            "''${spacer[@]}"

        # Spaces Bracket
        ${sketchyBarExe} \
          --add bracket spaces_bracket ${
            lib.strings.concatStringsSep " " (map (v: "\"space.${v}\"") spaceIndexes)
          } "spacer.2" "spacer.3" \
          --set spaces_bracket "''${blur_background[@]}"


        # Time
        ${sketchyBarExe} \
          --add item time right \
          --set time \
          script='${sketchyBarExe} -m --set $NAME label="$(date +%H:%M)"' update_freq=10 \
          icon.drawing=off label.padding_left=0 label.padding_right=20 \
          click_script="osascript -e 'tell application \"System Events\" to click menu bar item 1 of menu bar 1 of application process \"ControlCenter\"'"

        # Date
        ${sketchyBarExe} \
          --add item date right \
          --set date \
          script='${sketchyBarExe} -m --set $NAME label="$(date +%a\ %b\ %d)"' update_freq=60 \
          icon.drawing=off label.padding_left=16 label.padding_right=8 \
          click_script="open -a \"Calendar\""

        ## Bracket (Item groups)
        # Name: dt_bracket
        # Members: date, time
        ${sketchyBarExe} \
          --add bracket dt_bracket date time \
          --set dt_bracket "''${blur_background[@]}"

        # Spacer
        ${sketchyBarExe} \
          --add item spacer.5 right \
          --set spacer.5 \
            width=12 \
            "''${spacer[@]}"

        # Aliases mirror items of the original status bar
        ${lib.strings.concatStringsSep "\n" (map buildMenuBarItem MenuBarItems)}

        ## Bracket (Item groups)
        # Name: sysst_bracket
        # Members: battery
        ${sketchyBarExe} \
          --add bracket sysst_bracket ${
            lib.strings.concatStringsSep " " (map (v: "\"${v}\"") MenuBarItems)
          } \
          --set sysst_bracket "''${blur_background[@]}"

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
