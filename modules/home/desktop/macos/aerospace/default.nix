{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.macos.aerospace;
in
{
  options.bravo.desktop.macos.aerospace = {
    enable = mkEnableOption "AeroSpace tiling window manager";
  };

  config = mkIf cfg.enable {
    # Install AeroSpace via homebrew (since it's not in nixpkgs)
    # Users will need to install via: brew install --cask nikitabobko/tap/aerospace

    # AeroSpace configuration
    xdg.configFile."aerospace/aerospace.toml".text = ''
      # Reference: https://github.com/nikitabobko/AeroSpace

      # Start AeroSpace at login
      start-at-login = true

      # Normalizations. See: https://nikitabobko.github.io/AeroSpace/guide#normalization
      enable-normalization-flatten-containers = true
      enable-normalization-opposite-orientation-for-nested-containers = true

      # Mouse follows focus
      on-focused-monitor-changed = ['move-mouse monitor-lazy-center']

      # Gaps between windows
      [gaps]
      inner.horizontal = 4
      inner.vertical   = 4
      outer.left       = 0
      outer.bottom     = 0
      outer.top        = 0
      outer.right      = 0

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
      h = 'resize width -50'
      j = 'resize height +50'
      k = 'resize height -50'
      l = 'resize width +50'
      enter = 'mode main'
      esc = 'mode main'

      # Service mode bindings
      [mode.service.binding]
      esc = ['reload-config', 'mode main']
      r = ['flatten-workspace-tree', 'mode main']
      f = ['layout floating tiling', 'mode main']
      backspace = ['close-all-windows-but-current', 'mode main']

      # Workspace to monitor assignment (optional, adjust to your setup)
      [[on-window-detected]]
      if.app-id = 'com.apple.systempreferences'
      run = 'layout floating'

      [[on-window-detected]]
      if.app-id = 'com.apple.ActivityMonitor'
      run = 'layout floating'
    '';

    # Note: AeroSpace must be installed via Homebrew
    # Add installation instructions to home.file
    home.file.".config/aerospace/README.md".text = ''
      # AeroSpace Installation

      AeroSpace is not available in nixpkgs, so it must be installed via Homebrew:

      ```bash
      brew install --cask nikitabobko/tap/aerospace
      ```

      After installation, the configuration in `~/.config/aerospace/aerospace.toml`
      will be used automatically.

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
      - `H/J/K/L`: Resize window
      - `Enter/Esc`: Exit resize mode

      ## Service Mode
      - `Esc`: Reload config
      - `R`: Flatten workspace tree
      - `F`: Toggle floating
      - `Backspace`: Close all windows but current
    '';
  };
}
