{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.macos.aerospace;
  rosepine = lib.bravo.rose_pine;

  # Convert Rosé Pine colors to 0xAARRGGBB format (borders format)
  # TODO: move to bravo.desktop.theme
  toBorders = color: "0xff${color}";

  # Rosé Pine Moon colors
  colors = {
    transparent = "0x00${rosepine.moon.base}";
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
  options.bravo.desktop.macos.aerospace = {
    enable = mkEnableOption "AeroSpace tiling window manager";

    borders = {
      width = mkOption {
            type = types.float;
            default = 5.0;
            description = "Border width in pixels";
      };

      active_color = mkOption {
            type = types.str;
            default = colors.gold;
            description = "Color for active window border (0xAARRGGBB format)";
      };

      inactive_color = mkOption {
            type = types.str;
            default = colors.transparent;
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
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellApplication {
        name = "borders-run";
        runtimeInputs = [ pkgs.unstable.jankyborders ];
        text = ''
          exec borders \
            active_color=${cfg.borders.active_color} \
            inactive_color=${cfg.borders.inactive_color} \
            width=${toString cfg.borders.width} \
            ${if cfg.borders.hidpi then "hidpi=on" else "hidpi=off"} \
            style=${cfg.borders.style} \
            ${lib.optionalString (cfg.borders.blur > 0.0) "blur_radius=${toString cfg.borders.blur}"} \
            >>/tmp/borders.out.log 2>>/tmp/borders.err.log
        '';
      })
    ];

    xdg.configFile."aerospace/aerospace.toml".text = ''
      # Reference: https://github.com/nikitabobko/AeroSpace

      # Start AeroSpace at login
      start-at-login = true

      # When AeroSpace starts, enforce accordion layout and handle fallback if external is missing
      after-startup-command = [
        # Force accordion on both
        "layout h_accordion",
        "focus-monitor next",
        "layout h_accordion",
        "focus-monitor prev",

        # Fallback: if external monitor missing, collapse all workspaces to built-in
        # "exec-and-forget bash -lc 'if [ \"$(aerospace list-monitors | wc -l)\" -eq 1 ]; then for w in 2 3 4 5 6 7 8 9 10 11; do aerospace workspace \"$w\"; aerospace move-workspace-to-monitor --wrap-around prev; done; aerospace workspace 1; fi'"

        # Start Borders
        "exec-and-forget bash -lc 'pkill -x borders || true; exec ${config.home.profileDirectory}/bin/borders-run'"
      ]

      # Normalizations. See: https://nikitabobko.github.io/AeroSpace/guide#normalization
      enable-normalization-flatten-containers = true
      enable-normalization-opposite-orientation-for-nested-containers = true

      accordion-padding = 30

      # Possible values: tiles|accordion
      default-root-container-layout = 'accordion'

      # Possible values: horizontal|vertical|auto
      # 'auto' means: wide monitor (anything wider than high) gets horizontal orientation,
      #               tall monitor (anything higher than wide) gets vertical orientation
      default-root-container-orientation = 'auto'

      # Mouse lazily follows any focus (window or workspace)
      on-focus-changed = ['move-mouse window-lazy-center']

      # Static assignment when both monitors are connected
      [workspace-to-monitor-force-assignment]
      1  = "built-in"
      2  = "main"
      3  = "main"
      4  = "main"
      5  = "main"
      6  = "main"
      7  = "main"
      8  = "main"
      9  = "main"
      10 = "main"

      # Gaps between windows
      [gaps]
      inner.horizontal = 4
      inner.vertical   = 4
      outer.left       = 4
      outer.bottom     = 2
      outer.top        = 2
      outer.right      = 4

      # Mode descriptions
      [mode.main.binding]
      # See: https://nikitabobko.github.io/AeroSpace/commands

      # All possible keys:
      # - Letters:        a, b, c, ..., z
      # - Numbers:        0, 1, 2, ..., 9
      # - Special chars:  minus, equal, period, comma, slash, backslash, quote, semicolon, backtick,
      #                   leftSquareBracket, rightSquareBracket, space, enter, esc, backspace, tab
      # - Function keys:  f1, f2, ..., f20
      # - Keypad numbers: keypad0, keypad1, keypad2, ..., keypad9
      # - Keypad special: keypadClear, keypadDecimalMark, keypadDivide, keypadEnter, keypadEquals,
      #                   keypadMinus, keypadMultiply, keypadPlus
      # - Arrows:         left, down, up, right

      # All possible modifiers: cmd, alt, ctrl, shift

      # Alt+Enter → new Ghostty window on current workspace
      # alt-enter = '''exec-and-forget osascript
      #   -e 'tell application "Ghostty" to activate'
      #   -e 'delay 0.05'
      #   -e 'tell application "System Events" to keystroke "n" using command down'
      # '''
      alt-enter = "exec-and-forget open -n -a Ghostty"

      # Vim-style focus movement
      alt-h = 'focus left'
      alt-j = 'focus down'
      alt-k = 'focus up'
      alt-l = 'focus right'

      # Move windows with Vim keys
      alt-shift-h = 'move left'
      alt-shift-j = 'move down'
      alt-shift-k = 'move up'
      alt-shift-l = 'move right'

      # Resize mode
      alt-r = 'mode resize'

      # Workspace switching (1-9, 0 for 10)
      alt-1 = 'workspace 1'
      alt-2 = 'workspace 2'
      alt-3 = 'workspace 3'
      alt-4 = 'workspace 4'
      alt-5 = 'workspace 5'
      alt-6 = 'workspace 6'
      alt-7 = 'workspace 7'
      alt-8 = 'workspace 8'
      alt-9 = 'workspace 9'
      alt-0 = 'workspace 10'

      # Move window to workspace
      alt-shift-1 = 'move-node-to-workspace 1'
      alt-shift-2 = 'move-node-to-workspace 2'
      alt-shift-3 = 'move-node-to-workspace 3'
      alt-shift-4 = 'move-node-to-workspace 4'
      alt-shift-5 = 'move-node-to-workspace 5'
      alt-shift-6 = 'move-node-to-workspace 6'
      alt-shift-7 = 'move-node-to-workspace 7'
      alt-shift-8 = 'move-node-to-workspace 8'
      alt-shift-9 = 'move-node-to-workspace 9'
      alt-shift-0 = 'move-node-to-workspace 10'

      # See: https://nikitabobko.github.io/AeroSpace/commands#workspace-back-and-forth
      alt-tab = 'workspace-back-and-forth'
      # See: https://nikitabobko.github.io/AeroSpace/commands#move-workspace-to-monitor
      alt-shift-tab = 'move-workspace-to-monitor --wrap-around next'

      # Layout toggles
      alt-f = 'fullscreen'
      alt-s = 'layout v_accordion'  # stacking
      alt-w = 'layout h_accordion'  # tabbed
      alt-e = 'layout tiles horizontal vertical'  # toggle split

      # Toggle floating
      alt-shift-space = 'layout floating tiling'

      # Service mode for special commands
      alt-shift-semicolon = 'mode service'

      # Resize mode bindings
      [mode.resize.binding]
      esc = 'mode main'
      enter = 'mode main'
      h = 'resize width -50'
      j = 'resize height +50'
      k = 'resize height -50'
      l = 'resize width +50'

      # Service mode bindings
      [mode.service.binding]
      esc = ['reload-config', 'mode main']
      r = ['flatten-workspace-tree', 'mode main']
      f = ['layout floating tiling', 'mode main']
      backspace = ['close-all-windows-but-current', 'mode main']
      # Quit AeroSpace
      q = "exec-and-forget bash -c \"pkill -x borders || true; osascript -e 'tell application \\\"AeroSpace\\\" to quit'\""
      # Relaunch borders with current settings
      b = "exec-and-forget bash -lc 'pkill -x borders || true; exec ${config.home.profileDirectory}/bin/borders-run'"
      # Stop borders
      shift-b = "exec-and-forget bash -lc 'pkill -x borders'"

      # Workspace to monitor assignment (optional, adjust to your setup)
      # get app id: osascript -e 'id of app "My App"'
      [[on-window-detected]]
      if.app-id = 'com.apple.systempreferences'
      run = 'layout floating'

      [[on-window-detected]]
      if.app-id = 'com.apple.ActivityMonitor'
      run = 'layout floating'

      [[on-window-detected]]
      if.app-id = 'cc.ffitch.shottr'
      run = 'layout floating'
    '';

    # Add installation instructions to home.file
    home.file.".config/aerospace/README.md".text = ''
      # AeroSpace Installation

      To start AeroSpace:
      - It will auto-start at login (configured in aerospace.toml)
      - Or manually: `open -a AeroSpace`

      ## Key Bindings

      - `Alt+H/J/K/L`: Focus left/down/up/right (Vim-style)
      - `Alt+Shift+H/J/K/L`: Move window left/down/up/right
      - `Alt+1-9,0`: Switch to workspace 1-10
      - `Alt+Shift+1-9,0`: Move window to workspace 1-10
      - `Alt+F`: Toggle fullscreen
      - `Alt+Shift+Space`: Toggle floating
      - `Alt+R`: Enter resize mode
      - `Alt+Shift+;`: Enter service mode

      ## Resize Mode
      - `Enter/Esc`: Exit resize mode
      - `H/J/K/L`: Resize window

      ## Service Mode
      - `Esc`: Reload config
      - `R`: Flatten workspace tree
      - `F`: Toggle floating
      - `Backspace`: Close all windows but current
    '';
  };
}
