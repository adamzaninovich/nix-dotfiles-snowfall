{ lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.wayland;
in
{
  options.bravo.desktop.wayland = {
    enable = mkEnableOption "Complete Wayland desktop environment with Hyprland";
  };

  config = mkIf cfg.enable {
    bravo.desktop.gtk.enable = true;

    bravo.desktop.wayland = {
      hyprland.enable = true;
      waybar.enable = true;
      wofi.enable = true;
      swaync.enable = true;
    };
  };
}
