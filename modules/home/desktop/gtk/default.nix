{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.gtk;
  colors = config.bravo.desktop.theme.rosepine.colors;
in
{
  options.bravo.desktop.gtk = {
    enable = mkEnableOption "GTK theme configuration";
  };

  config = mkIf cfg.enable {
    gtk = {
      enable = true;

      iconTheme = {
        name = "rose-pine-moon";
        package = pkgs.rose-pine-icon-theme;
      };

      theme = {
        name = "rose-pine-moon";
        package = pkgs.rose-pine-gtk-theme;
      };

      cursorTheme = {
        name = "BreezeX-RosePine-Linux";
        package = pkgs.rose-pine-cursor;
        size = 24;
      };

      font = {
        name = "SF Pro Display";
        size = 11;
      };

      gtk3.extraConfig = {
        gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
        gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
        gtk-button-images = 0;
        gtk-menu-images = 0;
        gtk-enable-event-sounds = 1;
        gtk-enable-input-feedback-sounds = 0;
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintslight";
        gtk-xft-rgba = "rgb";
        gtk-application-prefer-dark-theme = 1;
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };

    home.packages = with pkgs; [
      # adwaita-icon-theme
      nautilus
      imv
      nwg-look
      pinta
      font-manager
    ];

    # Set dark color scheme preference
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "rose-pine-moon";
      };
    };

    # Ensure GTK applications can detect dark mode
    home.sessionVariables = {
      GTK_THEME = "rose-pine-moon:dark";
    };

    # Configure XDG MIME associations
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        # Image files
        "image/png" = "imv.desktop";
        "image/jpeg" = "imv.desktop";
        "image/jpg" = "imv.desktop";
        "image/gif" = "imv.desktop";
        "image/webp" = "imv.desktop";
        "image/bmp" = "imv.desktop";
        "image/tiff" = "imv.desktop";
        "image/svg+xml" = "imv.desktop";

        # Web browser (Zen Browser)
        "x-scheme-handler/http" = "zen-beta.desktop";
        "x-scheme-handler/https" = "zen-beta.desktop";
        "x-scheme-handler/chrome" = "zen-beta.desktop";
        "text/html" = "zen-beta.desktop";
        "application/x-extension-htm" = "zen-beta.desktop";
        "application/x-extension-html" = "zen-beta.desktop";
        "application/x-extension-shtml" = "zen-beta.desktop";
        "application/xhtml+xml" = "zen-beta.desktop";
        "application/x-extension-xhtml" = "zen-beta.desktop";
        "application/x-extension-xht" = "zen-beta.desktop";
      };
    };

    # Ensure icon cache is updated on activation
    home.activation.updateIconCache = config.lib.dag.entryAfter ["linkGeneration"] ''
      if [ -d "$HOME/.nix-profile/share/icons" ]; then
        $DRY_RUN_CMD ${pkgs.gtk3}/bin/gtk-update-icon-cache -f -t $HOME/.nix-profile/share/icons/* 2>/dev/null || true
      fi
    '';
  };
}
