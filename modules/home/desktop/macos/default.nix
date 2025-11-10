{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.macos;
in
{
  options.bravo.desktop.macos = {
    enable = mkEnableOption "Complete macOS desktop environment with AeroSpace";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      unstable.aerospace
      unstable.sketchybar
      unstable.jankyborders
    ];

    bravo.desktop.macos = {
      aerospace.enable = true;
      sketchybar.enable = true;
      borders.enable = true;
    };
  };
}
