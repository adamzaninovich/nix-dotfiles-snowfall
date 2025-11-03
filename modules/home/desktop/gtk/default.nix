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
        name = "BreezeX-RosePineDawn-Linux";
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

    # Create zen.desktop file for the stable zen command
    xdg.desktopEntries.zen = {
      name = "Zen Browser";
      genericName = "Web Browser";
      exec = "zen %U";
      terminal = false;
      categories = [ "Network" "WebBrowser" ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      icon = "zen-browser";
      startupNotify = true;
      settings = {
        StartupWMClass = "zen";
      };
      actions = {
        new-window = {
          name = "New Window";
          exec = "zen --new-window %U";
        };
        new-private-window = {
          name = "New Private Window";
          exec = "zen --private-window %U";
        };
        profile-manager = {
          name = "Profile Manager";
          exec = "zen --ProfileManager";
        };
      };
    };

    # Hide zen-beta.desktop from application launchers
    xdg.desktopEntries.zen-beta = {
      name = "Zen Browser (Beta)";
      settings = {
        Hidden = "true";
      };
    };

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
        "x-scheme-handler/http" = "zen.desktop";
        "x-scheme-handler/https" = "zen.desktop";
        "x-scheme-handler/chrome" = "zen.desktop";
        "text/html" = "zen.desktop";
        "application/x-extension-htm" = "zen.desktop";
        "application/x-extension-html" = "zen.desktop";
        "application/x-extension-shtml" = "zen.desktop";
        "application/xhtml+xml" = "zen.desktop";
        "application/x-extension-xhtml" = "zen.desktop";
        "application/x-extension-xht" = "zen.desktop";
      };
    };

    # Ensure icon cache is updated on activation
    home.activation.updateIconCache = config.lib.dag.entryAfter ["linkGeneration"] ''
      if [ -d "$HOME/.nix-profile/share/icons" ]; then
        $DRY_RUN_CMD ${pkgs.gtk3}/bin/gtk-update-icon-cache -f -t $HOME/.nix-profile/share/icons/* 2>/dev/null || true
      fi
    '';

    # Disable Zen Browser's default browser check
    home.file.".zen/user.js".text = ''
      // Don't check if Zen is the default browser
      user_pref("browser.shell.checkDefaultBrowser", false);
    '';
  };
}
