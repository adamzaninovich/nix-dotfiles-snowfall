{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.hyprland;
  colors = config.bravo.desktop.theme.rosepine.colors;

  # Helper to convert color list to Hyprland gradient format
  mkGradient = angle: colorList:
    builtins.concatStringsSep " " colorList + " ${toString angle}deg";
in
{
  options.bravo.desktop.hyprland = {
    enable = mkEnableOption "Hyprland window manager with hyprlock";

    wallpaperPath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/Pictures/wallpaper.png";
      description = "Path to wallpaper image";
    };
  };

  config = mkIf cfg.enable {
    # Enable Rose Pine theme
    bravo.desktop.theme.rosepine.enable = true;

    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        # Monitor configuration
        monitor = ",preferred,auto,auto";

        # Environment variables
        env = [
          "XCURSOR_SIZE,24"
          "HYPRCURSOR_SIZE,24"
          "SLURP_ARGS,-d -b -B F050F022 -b 10101022 -c ff00ff"
          "GRIMBLAST_HIDE_CURSOR,0"
        ];

        # Program variables
        "$terminal" = "ghostty";
        "$fileManager" = "dolphin";
        "$menu" = "wofi -n";
        "$lock" = "hyprlock";
        "$wallpaper" = "~/.local/bin/wallpaper.sh";
        "$mainMod" = "SUPER";

        # Autostart
        exec-once = [
          "waybar"
          "swww-daemon"
          "hyprctl setcursor BreezeX-RosePineDawn-Linux 24"
          "sleep .5 && swww restore"
          "swaync"
          "swaync-client -df"
        ];

        # General settings
        general = {
          gaps_in = 1;
          gaps_out = 0;
          border_size = 1;
          "col.active_border" = mkGradient 45 [
            colors.hyprland.gold
            colors.hyprland.rose
            colors.hyprland.pine
            colors.hyprland.iris
          ];
          "col.inactive_border" = colors.hyprland.muted;
          resize_on_border = true;
          allow_tearing = false;
          layout = "master";
        };

        # Decoration
        decoration = {
          rounding = 10;
          rounding_power = 2;
          active_opacity = 0.78;
          inactive_opacity = 0.68;
          fullscreen_opacity = 1.0;

          shadow = {
            enabled = true;
            range = 15;
            render_power = 5;
            color = "rgba(0,0,0,.5)";
          };

          blur = {
            enabled = true;
            size = 3;
            passes = 5;
            new_optimizations = true;
            ignore_opacity = true;
            xray = false;
            popups = true;
          };
        };

        # Animations
        animations = {
          enabled = true;
          bezier = [
            "fluid, 0.15, 0.85, 0.25, 1"
            "snappy, 0.3, 1, 0.4, 1"
          ];
          animation = [
            "windows, 1, 3, fluid, popin 5%"
            "windowsOut, 1, 2.5, snappy"
            "fade, 1, 4, snappy"
            "workspaces, 1, 1.7, snappy, slide"
            "specialWorkspace, 1, 4, fluid, slidefadevert -35%"
            "layers, 1, 2, snappy, popin 70%"
          ];
        };

        # Dwindle layout
        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        # Master layout
        master = {
          new_status = "slave";
          mfact = 0.55;
        };

        # Misc settings
        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
          focus_on_activate = true;
        };

        # Input configuration
        input = {
          kb_layout = "us";
          kb_options = "ctrl:nocaps";
          follow_mouse = 1;
          sensitivity = 0;

          touchpad = {
            natural_scroll = false;
          };
        };

        # Gestures
        gestures = {
          workspace_swipe = false;
        };

        # Device configuration
        device = {
          name = "epic-mouse-v1";
          sensitivity = 0;
        };

        # Keybindings
        bind = [
          # Window management
          "$mainMod, return, exec, $terminal"
          "$mainMod, Q, killactive,"
          "SUPER_SHIFT, Q, exit,"
          "$mainMod, E, exec, $fileManager"
          "$mainMod, V, togglefloating,"
          "ALT, space, exec, $menu"
          "$mainMod, W, exec, $wallpaper"
          "SUPER_SHIFT, L, exec, $lock"
          "$mainMod, F, fullscreen"
          "$mainMod, P, togglesplit,"

          # Master layout
          "$mainMod, M, layoutmsg, focusmaster master"
          "SUPER_SHIFT, M, layoutmsg, swapwithmaster master"

          # Screenshots
          "ALT SHIFT, 3, exec, grimblast save output"
          "ALT SHIFT, 4, exec, grimblast save area"
          "ALT SHIFT, 5, exec, grimblast save active"
          ", Print, exec, grimblast copy area"

          # Focus movement (arrow keys)
          "$mainMod, left, movefocus, l"
          "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"
          "$mainMod, down, movefocus, d"

          # Focus movement (vim keys)
          "$mainMod, H, movefocus, l"
          "$mainMod, L, movefocus, r"
          "$mainMod, K, movefocus, u"
          "$mainMod, J, movefocus, d"

          # Workspace switching
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"

          # Move window to workspace
          "$mainMod SHIFT, 1, movetoworkspace, 1"
          "$mainMod SHIFT, 2, movetoworkspace, 2"
          "$mainMod SHIFT, 3, movetoworkspace, 3"
          "$mainMod SHIFT, 4, movetoworkspace, 4"
          "$mainMod SHIFT, 5, movetoworkspace, 5"
          "$mainMod SHIFT, 6, movetoworkspace, 6"
          "$mainMod SHIFT, 7, movetoworkspace, 7"
          "$mainMod SHIFT, 8, movetoworkspace, 8"
          "$mainMod SHIFT, 9, movetoworkspace, 9"
          "$mainMod SHIFT, 0, movetoworkspace, 10"

          # Special workspace (scratchpad)
          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"

          # Mouse workspace switching
          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"
        ];

        # Mouse bindings
        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        # Repeat bindings (hold to repeat)
        bindel = [
          ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
          ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
        ];

        # Locked bindings (work even when locked)
        bindl = [
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
        ];

        # Layer rules
        layerrule = [
          "blur, waybar"
          "ignorezero, waybar"
          "ignorealpha 0.5, waybar"
          "blur, swaync-control-center"
          "blur, swaync-notification-window"
          "ignorezero, swaync-control-center"
          "ignorezero, swaync-notification-window"
          "ignorealpha 0.5, swaync-control-center"
          "ignorealpha 0.5, swaync-notification-window"
          "noanim, selection"
        ];

        # Window rules
        windowrule = [
          "suppressevent maximize, class:.*"
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        ];
      };
    };

    # Hyprlock configuration
    xdg.configFile."hypr/hyprlock.conf".text = ''
      background {
          monitor =
          path = ${cfg.wallpaperPath}
          blur_size = 5
          blur_passes = 3
          brightness = .6
      }

      input-field {
          monitor =
          size = 6%, 4%
          outline_thickness = 0
          dots_rounding = 4
          dots_spacing = .5
          dots_fase_time = 300
          inner_color = ${colors.hyprland.base}
          outer_color = ${colors.hyprland.base} ${colors.hyprland.base}
          check_color = ${colors.hyprland.base} ${colors.hyprland.base}
          fail_color = ${colors.hyprland.base} ${colors.hyprland.base}
          font_color = ${colors.hyprland.love}
          font_family = CodeNewRoman Nerd Font Propo
          fade_on_empty = false
          shadow_color = rgba(0,0,0,0.5)
          shadow_passes = 2
          shadow_size = 2
          rounding = 20
          placeholder_text = <i></i>
          fail_text = <b>FAIL</b>
          fail_timeout = 300
          position = 0, -100
          halign = center
          valign = center
      }

      label {
          monitor =
          text = cmd[update:1000] date +"<b>%I</b>"
          color = ${colors.hyprland.love}
          font_size = 200
          font_family = CodeNewRoman Nerd Font Propo
          shadow_passes = 0
          shadow_size = 5
          position = -120, 410
          halign = center
          valign = center
      }

      label {
          monitor =
          text = cmd[update:1000] date +"<b>%M</b>"
          color = rgba(150,150,150, .4)
          font_size = 200
          font_family = CodeNewRoman Nerd Font Propo
          shadow_passes = 0
          shadow_size = 5
          position = 120, 230
          halign = center
          valign = center
      }

      label {
          monitor =
          text = cmd[update:1000] date +"<b>%A, %B %d, %Y</b>"
          color = ${colors.hyprland.foam}
          font_size = 40
          font_family = CodeNewRoman Nerd Font Propo
          shadow_passes = 0
          shadow_size = 4
          position = -40,-20
          halign = right
          valign = top
      }

      label {
          monitor =
          text = <i>Hello</i> <b>$USER</b>
          color = ${colors.hyprland.iris}
          font_size = 40
          font_family = CodeNewRoman Nerd Font Propo
          shadow_passes = 0
          shadow_size = 4
          position = 40,-20
          halign = left
          valign = top
      }
    '';
  };
}
