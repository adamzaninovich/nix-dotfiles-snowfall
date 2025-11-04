{ lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.macos;
in
{
  options.bravo.desktop.macos = {
    enable = mkEnableOption "Complete macOS desktop environment with AeroSpace";
  };

  config = mkIf cfg.enable {
    bravo.desktop.macos = {
      aerospace.enable = true;
      sketchybar.enable = true;
      borders.enable = true;
    };
  };
}
