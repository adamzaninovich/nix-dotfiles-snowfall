{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.macos.borders;
  rosepine = lib.bravo.rose_pine;

  # Convert Rosé Pine colors to 0xAARRGGBB format (borders format)
  # TODO: move to bravo.desktop.theme
  toBorders = color: "0xff${color}";

  # Rosé Pine Moon colors
  colors = {
    base = toBorders rosepine.moon.base;
    surface = toBorders rosepine.moon.surface;
    overlay = toBorders rosepine.moon.overlay;
    muted = toBorders rosepine.moon.muted;
    subtle = toBorders rosepine.moon.subtle;
    text = toBorders rosepine.moon.text;
    love = toBorders rosepine.moon.love;
    gold = toBorders rosepine.moon.gold;
    rose = toBorders rosepine.moon.rose;
    pine = toBorders rosepine.moon.pine;
    foam = toBorders rosepine.moon.foam;
    iris = toBorders rosepine.moon.iris;
    highlightLow = toBorders rosepine.moon.highlightLow;
    highlightMed = toBorders rosepine.moon.highlightMed;
    highlightHigh = toBorders rosepine.moon.highlightHigh;
  };
in
{
  options.bravo.desktop.macos.borders = {
    enable = mkEnableOption "JankyBorders for window borders";

    width = mkOption {
      type = types.float;
      default = 5.0;
      description = "Border width in pixels";
    };

    activeColor = mkOption {
      type = types.str;
      default = colors.pine;
      description = "Color for active window border (0xAARRGGBB format)";
    };

    inactiveColor = mkOption {
      type = types.str;
      default = colors.muted;
      description = "Color for inactive window border (0xAARRGGBB format)";
    };

    hidpi = mkOption {
      type = types.bool;
      default = true;
      description = "Enable HiDPI support";
    };

    style = mkOption {
      type = types.enum [ "round" "square" ];
      default = "round";
      description = "Border corner style";
    };

    blur = mkOption {
      type = types.float;
      default = 0.0;
      description = "Blur radius for borders";
    };
  };

  config = mkIf cfg.enable {
    # LaunchAgent to start borders automatically
    # Note: This creates the plist, but borders must be installed via Homebrew
    home.file."Library/LaunchAgents/com.user.borders.plist".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>com.user.borders</string>
        <key>ProgramArguments</key>
        <array>
          <string>/opt/homebrew/bin/borders</string>
          <string>active_color=${cfg.activeColor}</string>
          <string>inactive_color=${cfg.inactiveColor}</string>
          <string>width=${toString cfg.width}</string>
          <string>${if cfg.hidpi then "hidpi=on" else "hidpi=off"}</string>
          <string>style=${cfg.style}</string>
          ${optionalString (cfg.blur > 0.0) "<string>blur_radius=${toString cfg.blur}</string>"}
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>StandardOutPath</key>
        <string>/tmp/borders.out.log</string>
        <key>StandardErrorPath</key>
        <string>/tmp/borders.err.log</string>
      </dict>
      </plist>
    '';

    # Installation README
    home.file.".config/borders/README.md".text = ''
      # JankyBorders Installation

      JankyBorders draws colored borders around windows to indicate focus.
      It must be installed via Homebrew:

      ```bash
      brew tap FelixKratz/formulae
      brew install borders
      ```

      ## Starting the Service

      The LaunchAgent is automatically configured. To load it:

      ```bash
      # Load the service
      launchctl load ~/Library/LaunchAgents/com.user.borders.plist

      # Or bootstrap it (preferred on newer macOS)
      launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.user.borders.plist
      ```

      ## Stopping the Service

      ```bash
      # Unload
      launchctl unload ~/Library/LaunchAgents/com.user.borders.plist

      # Or bootout
      launchctl bootout gui/$(id -u)/com.user.borders
      ```

      ## Configuration

      Current settings:
      - **Active color**: ${cfg.activeColor} (Rosé Pine Pine)
      - **Inactive color**: ${cfg.inactiveColor} (Rosé Pine Muted)
      - **Width**: ${toString cfg.width}px
      - **HiDPI**: ${if cfg.hidpi then "enabled" else "disabled"}
      - **Style**: ${cfg.style}
      ${optionalString (cfg.blur > 0.0) "- **Blur**: ${toString cfg.blur}px"}

      ## Customization

      To change border settings, modify your home configuration:

      ```nix
      bravo.desktop.macos.borders = {
        enable = true;
        width = 6.0;              # Thicker borders
        activeColor = "0xff31748f"; # Custom color
        style = "square";          # Square corners
        blur = 5.0;               # Add blur effect
      };
      ```

      Then rebuild and reload the service:
      ```bash
      darwin-rebuild switch --flake ~/.config/snowfall#rocinante
      launchctl bootout gui/$(id -u)/com.user.borders
      launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.user.borders.plist
      ```

      ## Integration with AeroSpace

      JankyBorders automatically detects focus changes from AeroSpace and
      updates the border colors accordingly. The active window will have
      a ${cfg.activeColor} border, while inactive windows will have
      a ${cfg.inactiveColor} border.

      ## Troubleshooting

      Check logs if borders aren't appearing:
      ```bash
      cat /tmp/borders.out.log
      cat /tmp/borders.err.log
      ```

      Verify the service is running:
      ```bash
      launchctl list | grep borders
      ps aux | grep borders
      ```
    '';

    # Helper script for reloading borders
    home.file.".local/bin/reload-borders" = {
      executable = true;
      text = ''
        #!/bin/bash

        echo "Reloading JankyBorders..."

        # Try to bootout if running
        launchctl bootout gui/$(id -u)/com.user.borders 2>/dev/null || true

        # Small delay
        sleep 0.5

        # Bootstrap
        launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.user.borders.plist

        echo "JankyBorders reloaded!"
      '';
    };
  };
}
