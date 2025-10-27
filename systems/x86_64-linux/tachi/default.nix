{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # is this needed since it's in the flake?
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "python-2.7.18.8" ];
  };

  # Networking
  networking = {
    hostId = "3fac5997";
    hostName = "tachi";
    networkmanager.enable = true;
    networkmanager.wifi.backend = "iwd";
  };

  # System Settings
  system.stateVersion = "25.05";
  time.timeZone = "America/Los_Angeles";
  console.useXkbConfig = true;
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Services
  services = {
    # printing.enable = true; # CUPS
    # flatpak.enable = true; # Flatpak
    # tailscale.enable = true; # Tailscale
    dbus.enable = true;
    libinput.enable = true; # Libinput
    fwupd.enable = true; # LVFS Firmware updates

    # Audio WHAT?
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # ZFS
    zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    # OpenSSH
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Enable Wayland and Hyprland
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
        options = "ctrl:nocaps";
      };
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
      windowManager.hypr.enable = true;
      # excludePackages = [ pkgs.xterm ];
    };
  };

  programs = {
    hyprland.enable = true;
    zsh.enable = true;
    nm-applet.enable = true;
    dconf.enable = true;

    # TODO: move 1pw to home config
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "adam" ];
    };
  };

  # might not be needed
  hardware = {
    bluetooth.enable = true;
    enableRedistributableFirmware = true;
  };

  users = {
    mutableUsers = true;
    users.adam = {
      isNormalUser = true;
      # add with sops, then remove mutableUsers
      # hashedPasswordFile = config.sops.secrets.adam-password.path;
      extraGroups = [ "wheel" "networkmanager" "docker" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBR/LutmCpH+8nq28MOQHhqGO0DzUol6AezcofX4cFPD openpgp:0x72A8654C"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1leExad18ykHxcnp7WXNzloBSnaZ+VVk9G7yTJeq5hj0n4PsM6Q4u7VzLPL5zIHU6GiD40Fq2iB2qJVCw8ZOKPtZ2xwWwK26rZrfi+2YHkUFG4XhfKBW0FNYPOrVnUSH73lpqLokVKDRPBDRhcXcSD5WHFGB5dVz2jgASp7G5kRCdG8I4R/ksCDF7jJyZY/vPEeC/6Yd90aeDYdqfVtyhtfburNAsYM+Pbm0r/Sxq2UHWDzqgcQlE52Xjv3G2PiUyuqhQCXDc669jwi65R+syT2m/ERiezctuiEVN/BRyZxUleKZMiVKOJY3cYCtb+tWLWYkTbT7AKYxxAetKGpqT openpgp:0x6131E5A3"
      ];
    };
  };

  security = {
    # needed for sound with pipewire.
    rtkit.enable = true;

    # Enable passwordless sudo
    sudo.extraRules = [
      {
        users = [ "adam" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };

  # needed?
  fonts.packages = [ ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  environment = {
    # Enable zsh system-wide
    shells = [ pkgs.zsh ];

    etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          zen
        '';
        mode = "0755";
      };
    };

    # Install some additional packages
    systemPackages = with pkgs; [
      # hyprland
      rose-pine-cursor
      rose-pine-hyprcursor
      nwg-look
      waybar
      hyprpicker
      hyprlock
      swww
      pywal
      python2
      blueman
      bluez
      pulseaudio
      networkmanager
      gnome-network-displays
      swaynotificationcenter
      kdePackages.dolphin
      wofi
      wl-clipboard
      # general
      usbutils
      neofetch
      git
      tree
      eza
      neovim
      zip
      unzip
      wget
      lm_sensors
      whois
      dig
      gnupg
      pika-backup
      localsend

      inputs.zen-browser.packages."${pkgs.system}".default
      inputs.comic-code.packages.${pkgs.system}.default

      # # Emacs with PGTK for proper Wayland support (fixes blurry text)
      # (emacs30.override {
      #   withPgtk = true;
      #   withTreeSitter = true;
      #   withWebP = true;
      #   withSQLite3 = true;
      # })
      # # needed for emacs vterm compilation
      # libtool
      nerd-fonts.symbols-only
    ];
  };
}
