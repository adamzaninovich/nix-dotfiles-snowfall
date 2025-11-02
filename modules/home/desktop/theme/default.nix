{ lib, config, inputs, ... }:

with lib;

let
  cfg = config.bravo.desktop.theme;

  rosepine = lib.bravo.rose_pine;

  # Color values - always available regardless of enable state
  colorValues = {
    # Raw palette (RRGGBB format)
    palette = rosepine.palette;
    terminal = rosepine.terminal;

    # Hyprland format (0xffRRGGBB)
    hyprland = lib.mapAttrs (_: rosepine.toHyprland) rosepine.palette // {
      foregroundCol = rosepine.toHyprland rosepine.palette.text;
      backgroundCol = rosepine.toHyprland rosepine.palette.base;
    };

    # CSS hex format (#RRGGBB)
    hex = lib.mapAttrs (_: rosepine.toHex) rosepine.palette;

    # CSS rgb() format
    rgb = lib.mapAttrs (_: rosepine.toRGB) rosepine.palette;

    # CSS rgba() format with custom alpha
    rgba = alpha: lib.mapAttrs (_: rosepine.toRGBA alpha) rosepine.palette;

    # Helper functions (exported for custom usage)
    helpers = {
      inherit (rosepine) toHyprland toHex toRGB toRGBA;
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
