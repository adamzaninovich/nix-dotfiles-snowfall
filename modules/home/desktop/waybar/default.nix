{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.waybar;
  colors = config.bravo.desktop.theme.rosepine.colors;

  # Colorpicker script (pywal dependency removed)
  colorpickerScript = pkgs.writeShellScript "colorpicker.sh" ''
    #!/usr/bin/env bash
    check() {
      command -v "$1" 1>/dev/null
    }

    loc="$HOME/.cache/colorpicker"
    [ -d "$loc" ] || mkdir -p "$loc"
    [ -f "$loc/colors" ] || touch "$loc/colors"

    limit=10

    [[ $# -eq 1 && $1 = "-l" ]] && {
      cat "$loc/colors"
      exit
    }

    [[ $# -eq 1 && $1 = "-j" ]] && {
      text="$(head -n 1 "$loc/colors")"
      text=''${text:-#FFFFFF} #if we start for the first time ever the file is empty and thus waybar will throw an error and not display the colorpicker. here is a fallback for that

      mapfile -t allcolors < <(tail -n +2 "$loc/colors")
      tooltip="<b>   COLORS</b>\n\n"

      tooltip+="-> <b>$text</b>  <span color='$text'></span>  \n"
      for i in "''${allcolors[@]}"; do
        tooltip+="   <b>$i</b>  <span color='$i'></span>  \n"
      done

      cat <<EOF
    { "text":"<span color='$text'></span>", "tooltip":"$tooltip"}
    EOF

      exit
    }

    check hyprpicker || {
      notify-send "hyprpicker is not installed"
      exit
    }
    killall -q hyprpicker
    color=$(hyprpicker | grep -v "^\[ERR\]")
    [[ -n $color ]] || exit

    check wl-copy && {
      echo "$color" | sed -z 's/\n//g' | wl-copy
    }

    prevColors=$(head -n $((limit - 1)) "$loc/colors")

    # Generate color preview image
    color_preview=""
    check magick && {
      magick -size 64x64 canvas:"$color" "$loc/color_preview.png"
      color_preview="$loc/color_preview.png"
    }

    echo "$color" >"$loc/colors"
    echo "$prevColors" >>"$loc/colors"
    sed -i '/^$/d' "$loc/colors"

    if [ -n "$color_preview" ]; then
      notify-send "Color Picker" "This color has been selected: $color" -i "$color_preview"
    else
      notify-send "Color Picker" "This color has been selected: $color"
    fi

    pkill -RTMIN+1 waybar
  '';

in
{
  options.bravo.desktop.waybar = {
    enable = mkEnableOption "Waybar status bar";
  };

  config = mkIf cfg.enable {
    # Enable Rose Pine theme
    bravo.desktop.theme.rosepine.enable = true;

    programs.waybar = {
      enable = true;

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          reload_style_on_change = true;

          modules-left = [
            "custom/notification"
            "clock"
            "custom/pacman"
          ];

          modules-center = [
            "hyprland/workspaces"
          ];

          modules-right = [
            "tray"
            "group/expand"
            "bluetooth"
            "network"
            "battery"
          ];

          "hyprland/workspaces" = {
            format = "{icon}";
            format-icons = {
              active = "";
              default = "";
              empty = "";
            };
            persistent-workspaces = {
              "*" = [ 1 2 3 4 5 ];
            };
          };

          "custom/notification" = {
            tooltip = false;
            format = "";
            on-click = "swaync-client -t -sw";
            escape = true;
          };

          clock = {
            format = "{:%b %d %I:%M %p} ";
            interval = 1;
            tooltip-format = "<tt>{calendar}</tt>";
            calendar = {
              format = {
                today = "<span color='${colors.hex.pine}'><b>{}</b></span>";
              };
            };
            actions = {
              on-click-right = "shift_down";
              on-click = "shift_up";
            };
          };

          network = {
            format-wifi = " ";
            format-ethernet = " ";
            format-disconnected = " ";
            tooltip-format-disconnected = "Error";
            tooltip-format-wifi = "{essid} ({signalStrength}%) ";
            tooltip-format-ethernet = "{ifname} 🖧 ";
            on-click = "ghostty -e nmtui";
          };

          bluetooth = {
            format-on = "󰂯";
            format-off = "BT-off";
            format-disabled = "󰂲";
            format-connected-battery = "{device_battery_percentage}% 󰂯";
            format-alt = "{device_alias} 󰂯";
            tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
            tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}\n{device_address}";
            tooltip-format-enumerate-connected-battery = "{device_alias}\n{device_address}\n{device_battery_percentage}%";
            on-click-right = "blueman-manager";
          };

          battery = {
            interval = 30;
            states = {
              good = 95;
              warning = 30;
              critical = 20;
            };
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = " {capacity}%";
            format-alt = "{time} {icon}";
            format-icons = [
              "󰁻"
              "󰁼"
              "󰁾"
              "󰂀"
              "󰂂"
              "󰁹"
            ];
          };

          "custom/expand" = {
            format = "";
            tooltip = false;
          };

          "custom/endpoint" = {
            format = "|";
            tooltip = false;
          };

          "group/expand" = {
            orientation = "horizontal";
            drawer = {
              transition-duration = 600;
              transition-to-left = true;
              click-to-reveal = true;
            };
            modules = [
              "custom/expand"
              "custom/colorpicker"
              "cpu"
              "memory"
              "temperature"
              "custom/endpoint"
            ];
          };

          "custom/colorpicker" = {
            format = "{}";
            return-type = "json";
            interval = "once";
            exec = "${colorpickerScript} -j";
            on-click = toString colorpickerScript;
            signal = 1;
          };

          cpu = {
            format = "󰻠";
            tooltip = true;
          };

          memory = {
            format = "";
          };

          temperature = {
            critical-threshold = 80;
            format = "";
          };

          tray = {
            icon-size = 14;
            spacing = 5;
          };
        };
      };

      style = ''
        * {
            font-size: 12px;
            font-family: "SF Pro Display", "Symbols Nerd Font Mono";
        }

        window#waybar {
            all: unset;
        }

        .modules-left {
            padding-top: 5px;
            padding-left: 5px;
            padding-bottom: 5px;
        }

        .modules-center {
            padding-top: 5px;
            padding-bottom: 5px;
        }

        .modules-right {
            padding-top: 5px;
            padding-right: 5px;
            padding-bottom: 5px;
        }

        tooltip {
            background: ${colors.hex.base};
            color: ${colors.hex.text};
        }

        #clock:hover, #custom-pacman:hover, #custom-notification:hover,
        #bluetooth:hover, #network:hover, #battery:hover,
        #cpu:hover, #memory:hover, #temperature:hover {
            transition: all .3s ease;
            color: ${colors.hex.love};
        }

        #custom-notification {
            padding: 0px 5px;
            transition: all .3s ease;
            color: ${colors.hex.text};
        }

        #clock {
            padding: 0px 5px;
            color: ${colors.hex.text};
            transition: all .3s ease;
        }

        #custom-pacman {
            padding: 0px 5px;
            transition: all .3s ease;
            color: ${colors.hex.text};
        }

        #workspaces {
            padding: 0px 5px;
        }

        #workspaces button {
            all: unset;
            padding: 0px 5px;
            color: alpha(${colors.hex.pine}, .4);
            transition: all .2s ease;
        }

        #workspaces button:hover {
            color: alpha(${colors.hex.pine}, .8);
            border: none;
            text-shadow: 0px 0px 1.5px rgba(0, 0, 0, .5);
            transition: all 1s ease;
        }

        #workspaces button.active {
            color: ${colors.hex.gold};
            border: none;
            text-shadow: 0px 0px 2px rgba(0, 0, 0, .5);
        }

        #workspaces button.empty {
            color: rgba(0, 0, 0, 0);
            border: none;
            text-shadow: 0px 0px 1.5px rgba(0, 0, 0, .2);
        }

        #workspaces button.empty:hover {
            color: alpha(${colors.hex.iris}, .5);
            border: none;
            text-shadow: 0px 0px 1.5px rgba(0, 0, 0, .5);
            transition: all 1s ease;
        }

        #workspaces button.empty.active {
            color: ${colors.hex.gold};
            border: none;
            text-shadow: 0px 0px 2px rgba(0, 0, 0, .5);
        }

        #bluetooth {
            padding: 0px 5px;
            transition: all .3s ease;
            color: ${colors.hex.text};
        }

        #network {
            padding: 0px 5px;
            transition: all .3s ease;
            color: ${colors.hex.text};
        }

        #battery {
            padding: 0px 5px;
            transition: all .3s ease;
            color: ${colors.hex.text};
        }

        #battery.charging {
            color: ${colors.hex.pine};
        }

        #battery.warning:not(.charging) {
            color: ${colors.hex.gold};
        }

        #battery.critical:not(.charging) {
            color: ${colors.hex.love};
            animation-name: blink;
            animation-duration: 0.5s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
        }

        #group-expand {
            padding: 0px 5px;
            transition: all .3s ease;
        }

        #custom-expand {
            padding: 0px 5px;
            color: alpha(${colors.hex.text}, .2);
            text-shadow: 0px 0px 2px rgba(0, 0, 0, .7);
            transition: all .3s ease;
        }

        #custom-expand:hover {
            color: rgba(255, 255, 255, .2);
            text-shadow: 0px 0px 2px rgba(255, 255, 255, .5);
        }

        #custom-colorpicker {
            padding: 0px 5px;
        }

        #cpu, #memory, #temperature {
            padding: 0px 5px;
            transition: all .3s ease;
            color: ${colors.hex.text};
        }

        #custom-endpoint {
            color: transparent;
            text-shadow: 0px 0px 1.5px rgba(0, 0, 0, 1);
        }

        #tray {
            padding: 0px 5px;
            transition: all .3s ease;
        }

        #tray menu * {
            padding: 0px 5px;
            transition: all .3s ease;
        }

        #tray menu separator {
            padding: 0px 5px;
            transition: all .3s ease;
        }
      '';
    };
  };
}
