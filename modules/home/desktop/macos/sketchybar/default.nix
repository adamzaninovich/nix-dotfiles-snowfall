{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.macos.sketchybar;
  rosepine = lib.bravo.rose_pine;

  # Convert Rosé Pine colors to 0xAARRGGBB format (sketchybar format)
  # TODO: move function to bravo.desktop.theme
  toSketchybar = color: "0xff${color}";

  # Rosé Pine Moon colors in sketchybar format
  colors = {
    base = toSketchybar rosepine.moon.base;
    surface = toSketchybar rosepine.moon.surface;
    overlay = toSketchybar rosepine.moon.overlay;
    muted = toSketchybar rosepine.moon.muted;
    subtle = toSketchybar rosepine.moon.subtle;
    text = toSketchybar rosepine.moon.text;
    love = toSketchybar rosepine.moon.love;
    gold = toSketchybar rosepine.moon.gold;
    rose = toSketchybar rosepine.moon.rose;
    pine = toSketchybar rosepine.moon.pine;
    foam = toSketchybar rosepine.moon.foam;
    iris = toSketchybar rosepine.moon.iris;
    highlightLow = toSketchybar rosepine.moon.highlightLow;
    highlightMed = toSketchybar rosepine.moon.highlightMed;
    highlightHigh = toSketchybar rosepine.moon.highlightHigh;
  };
in
{
  options.bravo.desktop.macos.sketchybar = {
    enable = mkEnableOption "SketchyBar status bar for macOS";
  };

  config = mkIf cfg.enable {
    # SketchyBar configuration
    xdg.configFile."sketchybar/sketchybarrc" = {
      executable = true;
      text = ''
        #!/bin/bash

        # SketchyBar configuration with Rosé Pine Moon theme
        # https://felixkratz.github.io/SketchyBar/

        PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

        ##### Bar Appearance #####
        sketchybar --bar height=32 \
                         blur_radius=30 \
                         position=top \
                         sticky=on \
                         padding_left=10 \
                         padding_right=10 \
                         color=${colors.base}

        ##### Changing Defaults #####
        sketchybar --default icon.font="SF Pro:Semibold:15.0" \
                             icon.color=${colors.text} \
                             label.font="SF Pro:Semibold:15.0" \
                             label.color=${colors.text} \
                             padding_left=5 \
                             padding_right=5 \
                             label.padding_left=4 \
                             label.padding_right=4 \
                             icon.padding_left=4 \
                             icon.padding_right=4

        ##### Adding Left Items #####
        # Spaces (workspaces)
        SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")
        for i in "''${!SPACE_ICONS[@]}"
        do
          sid=$(($i+1))
          sketchybar --add space space.$sid left \
                     --set space.$sid associated_space=$sid \
                                      icon=''${SPACE_ICONS[i]} \
                                      icon.padding_left=8 \
                                      icon.padding_right=8 \
                                      background.color=${colors.overlay} \
                                      background.corner_radius=5 \
                                      background.height=20 \
                                      background.drawing=on \
                                      label.drawing=off \
                                      script="$PLUGIN_DIR/space.sh" \
                                      click_script="aerospace workspace $sid"
        done

        ##### Adding Right Items #####
        sketchybar --add item clock right \
                   --set clock update_freq=10 \
                               icon= \
                               script="$PLUGIN_DIR/clock.sh"

        sketchybar --add item wifi right \
                   --set wifi script="$PLUGIN_DIR/wifi.sh" \
                              icon=󰖩 \
                              update_freq=10

        sketchybar --add item battery right \
                   --set battery script="$PLUGIN_DIR/battery.sh" \
                                 update_freq=120 \
                                 click_script="open -a 'System Settings' 'x-apple.systempreferences:com.apple.preference.battery'"

        sketchybar --add item volume right \
                   --set volume script="$PLUGIN_DIR/volume.sh" \
                                click_script="osascript -e 'set volume output muted not (output muted of (get volume settings))'"

        ##### Finalizing Setup #####
        sketchybar --update
      '';
    };

    # Space indicator script
    xdg.configFile."sketchybar/plugins/space.sh" = {
      executable = true;
      text = ''
        #!/bin/bash

        # Get current workspace from aerospace
        FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)

        if [ "$FOCUSED_WORKSPACE" = "$SID" ]; then
          sketchybar --set $NAME background.color=${colors.pine} \
                                icon.color=${colors.base}
        else
          sketchybar --set $NAME background.color=${colors.overlay} \
                                icon.color=${colors.text}
        fi
      '';
    };

    # Clock script
    xdg.configFile."sketchybar/plugins/clock.sh" = {
      executable = true;
      text = ''
        #!/bin/bash

        sketchybar --set $NAME label="$(date '+%b %d %I:%M %p')" \
                              icon.color=${colors.foam}
      '';
    };

    # WiFi script
    xdg.configFile."sketchybar/plugins/wifi.sh" = {
      executable = true;
      text = ''
        #!/bin/bash

        CURRENT_WIFI="$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I)"
        SSID="$(echo "$CURRENT_WIFI" | grep -o "SSID: .*" | sed 's/^SSID: //')"
        CURR_TX="$(echo "$CURRENT_WIFI" | grep -o "lastTxRate: .*" | sed 's/^lastTxRate: //')"

        if [ "$SSID" = "" ]; then
          sketchybar --set $NAME label="Disconnected" \
                                icon.color=${colors.love}
        else
          sketchybar --set $NAME label="$SSID" \
                                icon.color=${colors.pine}
        fi
      '';
    };

    # Battery script
    xdg.configFile."sketchybar/plugins/battery.sh" = {
      executable = true;
      text = ''
        #!/bin/bash

        PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
        CHARGING=$(pmset -g batt | grep 'AC Power')

        if [ $PERCENTAGE = "" ]; then
          exit 0
        fi

        case ''${PERCENTAGE} in
          9[0-9]|100) ICON=""
          ;;
          [6-8][0-9]) ICON=""
          ;;
          [3-5][0-9]) ICON=""
          ;;
          [1-2][0-9]) ICON=""
          ;;
          *) ICON=""
        esac

        if [[ $CHARGING != "" ]]; then
          ICON=""
          COLOR=${colors.pine}
        elif [[ $PERCENTAGE -lt 20 ]]; then
          COLOR=${colors.love}
        else
          COLOR=${colors.text}
        fi

        sketchybar --set $NAME icon="$ICON" \
                              label="$PERCENTAGE%" \
                              icon.color=$COLOR
      '';
    };

    # Volume script
    xdg.configFile."sketchybar/plugins/volume.sh" = {
      executable = true;
      text = ''
        #!/bin/bash

        VOLUME=$(osascript -e "output volume of (get volume settings)")
        MUTED=$(osascript -e "output muted of (get volume settings)")

        if [[ $MUTED = "true" ]]; then
          ICON="󰝟"
          COLOR=${colors.muted}
        else
          case ''${VOLUME} in
            [7-9][0-9]|100) ICON="󰕾"
            ;;
            [4-6][0-9]) ICON="󰖀"
            ;;
            [1-3][0-9]) ICON="󰕿"
            ;;
            *) ICON="󰝟"
          esac
          COLOR=${colors.text}
        fi

        sketchybar --set $NAME icon="$ICON" \
                              label="$VOLUME%" \
                              icon.color=$COLOR
      '';
    };

    # Installation README
    home.file.".config/sketchybar/README.md".text = ''
      # SketchyBar Installation

      SketchyBar is not available in nixpkgs, so it must be installed via Homebrew:

      ```bash
      brew install --cask sf-symbols  # Optional but recommended for icons
      brew install sketchybar
      brew services start sketchybar
      ```

      The configuration is managed by Nix and located at:
      - Config: `~/.config/sketchybar/sketchybarrc`
      - Plugins: `~/.config/sketchybar/plugins/`

      ## Features

      - **Workspace indicators**: Shows AeroSpace workspaces 1-10
      - **Clock**: Current date and time
      - **WiFi**: Connection status and SSID
      - **Battery**: Charge level with charging indicator
      - **Volume**: Current volume level with mute indicator

      ## Theme

      Uses Rosé Pine Moon color scheme to match the rest of your setup.

      ## Reload

      After making changes, reload SketchyBar:
      ```bash
      brew services restart sketchybar
      ```
      or
      ```bash
      sketchybar --reload
      ```
    '';
  };
}
