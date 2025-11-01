{ lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.wayland-desktop;
in
{
  options.bravo.desktop.wayland-desktop = {
    enable = mkEnableOption "Complete Wayland desktop environment with Hyprland";
  };

  config = mkIf cfg.enable {
    bravo.desktop = {
      hyprland.enable = true;
      waybar.enable = true;
      wofi.enable = true;
      swaync.enable = true;
    };
  };
}
