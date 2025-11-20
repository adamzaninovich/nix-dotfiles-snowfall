{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.wayland;
in
{
  options.bravo.desktop.wayland = {
    enable = mkEnableOption "Complete Wayland desktop environment";

    flavor = mkOption {
      type = types.enum [ "hyprland" "niri" ];
      default = "hyprland";
      description = ''
        The Wayland compositor flavor to use.
        - hyprland: Hyprland with waybar, wofi, and swaync
        - niri: Niri with noctalia-shell and fuzzel
      '';
    };
  };

  config = mkIf cfg.enable {
    bravo.desktop.gtk.enable = true;

    services.gnome-keyring.enable = true;
    home.packages = [ pkgs.gcr ]; # Provides org.gnome.keyring.SystemPrompter

    bravo.desktop.wayland = {
      # Hyprland stack
      hyprland.enable = cfg.flavor == "hyprland";
      waybar.enable = cfg.flavor == "hyprland";
      wofi.enable = cfg.flavor == "hyprland";
      swaync.enable = cfg.flavor == "hyprland";

      # Niri stack
      niri.enable = cfg.flavor == "niri";
    };
  };
}
