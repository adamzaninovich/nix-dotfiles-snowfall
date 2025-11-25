{ pkgs, lib, ... }:

# Shared macOS system defaults that auto-apply to all darwin systems.
# All settings use lib.mkDefault so they can be overridden per-system.

{
  # Determinate Nix manages the daemon completely
  # Configure Nix settings via Determinate instead of nix-darwin
  nix.enable = lib.mkDefault false;

  nixpkgs = {
    config = {
      allowUnfree = lib.mkDefault true;
      allowUnsupportedSystems = lib.mkDefault true;
    };
    hostPlatform = lib.mkDefault "aarch64-darwin";
  };

  # ZSH is the default shell for all systems
  programs.zsh.enable = lib.mkDefault true;

  # Enable documentation and man pages
  documentation.enable = lib.mkDefault true;
  documentation.man.enable = lib.mkDefault true;

  # SSH server configuration - prevent TERM variable override
  services.openssh.enable = lib.mkDefault true;

  # Configure sshd via environment.etc (extraConfig doesn't exist in nix-darwin)
  environment.etc."ssh/sshd_config.d/100-nix-darwin.conf" = {
    text = lib.mkDefault ''
      # Don't accept TERM from SSH clients - use the shell's default instead
      # This prevents terminals like Ghostty from overriding TERM with their own values
      AcceptEnv LANG LC_*
    '';
  };

  system = {
    stateVersion = lib.mkDefault 5;

    defaults = {
      # Dock settings - autohide with fast animations
      dock = {
        autohide = lib.mkDefault true;
        autohide-delay = lib.mkDefault 0.0;
        autohide-time-modifier = lib.mkDefault 0.4;
        mineffect = lib.mkDefault "scale";
        show-recents = lib.mkDefault false;
        tilesize = lib.mkDefault 49;

        # Hot corners for quick access
        wvous-tl-corner = lib.mkDefault 2;  # Mission Control
        wvous-tr-corner = lib.mkDefault 14; # Quick Note
        wvous-bl-corner = lib.mkDefault 6;  # Launchpad
        wvous-br-corner = lib.mkDefault 4;  # Desktop
      };

      # Finder settings - show all the things
      finder = {
        AppleShowAllExtensions = lib.mkDefault true;
        ShowPathbar = lib.mkDefault true;
        ShowStatusBar = lib.mkDefault true;
        FXPreferredViewStyle = lib.mkDefault "Nlsv"; # List view
        QuitMenuItem = lib.mkDefault true;
        _FXShowPosixPathInTitle = lib.mkDefault true;
      };

      # Global macOS settings
      NSGlobalDomain = {
        AppleInterfaceStyle = lib.mkDefault "Dark";
        AppleShowAllExtensions = lib.mkDefault true;
        AppleMeasurementUnits = lib.mkDefault "Inches";
        AppleTemperatureUnit = lib.mkDefault "Fahrenheit";
      };

      # Trackpad settings - tap to click and three-finger drag
      trackpad = {
        Clicking = lib.mkDefault true;
        TrackpadRightClick = lib.mkDefault true;
        TrackpadThreeFingerDrag = lib.mkDefault true;
      };

      # Menu bar clock - show all details
      menuExtraClock = {
        ShowSeconds = lib.mkDefault true;
        ShowDayOfWeek = lib.mkDefault true;
        ShowAMPM = lib.mkDefault true;
      };

      # Screenshots - save to Workspace as PNG
      screencapture = {
        location = lib.mkDefault "~/Workspace";
        type = lib.mkDefault "png";
      };
    };
  };

  # Security configuration - passwordless sudo for admin group
  security.sudo.extraConfig = lib.mkDefault ''
    %admin ALL=(ALL) NOPASSWD: ALL
  '';
}
