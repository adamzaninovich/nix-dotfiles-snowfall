{ lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.theme;

  # Core palette colors
  palette = {
    base = "232136";
    surface = "2a273f";
    overlay = "393552";
    muted = "6e6a86";
    subtle = "908caa";
    text = "e0def4";
    love = "eb6f92";
    gold = "f6c177";
    rose = "ea9a97";
    pine = "3e8fb0";
    foam = "9ccfd8";
    iris = "c4a7e7";
    highlightLow = "2a283e";
    highlightMed = "44415a";
    highlightHigh = "56526e";
  };

  # Terminal colors (0-15)
  terminal = {
    color0 = palette.overlay;
    color1 = palette.love;
    color2 = palette.pine;
    color3 = palette.gold;
    color4 = palette.foam;
    color5 = palette.iris;
    color6 = palette.rose;
    color7 = palette.text;
    color8 = palette.muted;
    color9 = palette.love;
    color10 = palette.pine;
    color11 = palette.gold;
    color12 = palette.foam;
    color13 = palette.iris;
    color14 = palette.rose;
    color15 = palette.text;
  };

  # Helper functions for different color formats
  toHyprland = color: "0xff${color}";
  toHex = color: "#${color}";
  toRGB = color:
    let
      r = lib.toInt ("0x" + builtins.substring 0 2 color);
      g = lib.toInt ("0x" + builtins.substring 2 2 color);
      b = lib.toInt ("0x" + builtins.substring 4 2 color);
    in "rgb(${toString r}, ${toString g}, ${toString b})";
  toRGBA = alpha: color:
    let
      r = lib.toInt ("0x" + builtins.substring 0 2 color);
      g = lib.toInt ("0x" + builtins.substring 2 2 color);
      b = lib.toInt ("0x" + builtins.substring 4 2 color);
    in "rgba(${toString r}, ${toString g}, ${toString b}, ${alpha})";

  # Color values - always available regardless of enable state
  colorValues = {
    # Raw palette (RRGGBB format)
    palette = palette;
    terminal = terminal;

    # Hyprland format (0xffRRGGBB)
    hyprland = lib.mapAttrs (_: toHyprland) palette // {
      foregroundCol = toHyprland palette.text;
      backgroundCol = toHyprland palette.base;
    };

    # CSS hex format (#RRGGBB)
    hex = lib.mapAttrs (_: toHex) palette;

    # CSS rgb() format
    rgb = lib.mapAttrs (_: toRGB) palette;

    # CSS rgba() format with custom alpha
    rgba = alpha: lib.mapAttrs (_: toRGBA alpha) palette;

    # Helper functions (exported for custom usage)
    helpers = {
      inherit toHyprland toHex toRGB toRGBA;
    };
  };
in
{
  options.bravo.desktop.theme.rosepine = {
    enable = mkEnableOption "Rosé Pine Moon color scheme";

    colors = mkOption {
      type = types.attrs;
      readOnly = true;
      default = colorValues;
      description = "Rosé Pine Moon color palette in various formats";
    };
  };

  config = mkIf cfg.rosepine.enable {
    # Theme is enabled, no additional config needed
    # Colors are always available via the option above
  };
}
