{ pkgs, inputs, config, ... }:

{
  # Determinate Nix manages the daemon completely
  # Configure Nix settings via Determinate instead of nix-darwin
  nix.enable = false;

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystems = true;
    };
    hostPlatform = "aarch64-darwin";
  };

  system.primaryUser = "adam";
  networking.hostName = "rocinante";
  networking.computerName = "rocinante";

  programs.zsh.enable = true;

  users = {
    users.adam = {
      home = "/Users/adam";
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
      ];
    };
  };

  # documentation.enable = true;
  # documentation.man.enable = true;

  system = {
    stateVersion = 5;

    defaults = {
      # Dock settings
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.4;
        mineffect = "scale";
        show-recents = false;
        tilesize = 49;

        # Hot corners
        wvous-tl-corner = 2;  # Mission Control
        wvous-tr-corner = 14; # Quick Note
        wvous-bl-corner = 6;  # Launchpad
        wvous-br-corner = 4;  # Desktop
      };

      # Finder settings
      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        FXPreferredViewStyle = "Nlsv"; # List view
        QuitMenuItem = true;
        _FXShowPosixPathInTitle = true;
      };

      # NSGlobalDomain settings
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        AppleMeasurementUnits = "Inches";
        AppleTemperatureUnit = "Fahrenheit";
      };

      # Trackpad settings
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
      };

      # Menu bar clock
      menuExtraClock = {
        ShowSeconds = true;
        ShowDayOfWeek = true;
        ShowAMPM = true;
      };

      # Screenshots
      screencapture = {
        location = "~/Workspace";
        type = "png";
      };
    };
  };

  # Security configuration
  security.sudo.extraConfig = ''
    %admin ALL=(ALL) NOPASSWD: ALL
  '';
}
