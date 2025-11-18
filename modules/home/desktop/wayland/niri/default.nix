{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.wayland.niri;
  # colors = config.bravo.desktop.theme.rosepine.colors;
in
{
  options.bravo.desktop.wayland.niri = {
    enable = mkEnableOption "Niri window manager with noctalia-shell and fuzzel";
  };

  config = mkIf cfg.enable {
    # Enable Rose Pine theme (don't need until we add the config)
    # bravo.desktop.theme.rosepine.enable = true;

    # Install niri and related tools from unstable
    home.packages = with pkgs; [
      unstable.niri
      unstable.xwayland-satellite
      swaybg # wallpaper
      # noctalia-shell will be added once configured
    ];

    programs.fuzzel.enable = true; # Super+D in the default setting (app launcher)
    # programs.swaylock.enable = true; # Super+Alt+L in the default setting (screen locker)
    # services.mako.enable = true; # notification daemon
    # services.swayidle.enable = true; # idle management daemon
    # services.polkit-gnome.enable = true; # polkit

    # Configuration will be managed externally for now
    # Once finalized, it can be moved here via:
    # xdg.configFile."niri/config.kdl".source = ./config.kdl;
  };
}
