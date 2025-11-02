{ config, lib, pkgs, inputs, ... }:

let
  rosepine = lib.bravo.rose_pine;
in
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

  # Console settings with rose-pine colors for tuigreet
  console = {
    useXkbConfig = true;
    colors = [
      rosepine.moon.base        # Darker background (was: rosepine.terminal.color0)
      rosepine.terminal.color1
      rosepine.terminal.color2
      rosepine.terminal.color3
      rosepine.terminal.color4
      rosepine.terminal.color5
      rosepine.terminal.color6
      rosepine.terminal.color7
      rosepine.terminal.color8
      rosepine.terminal.color9
      rosepine.terminal.color10
      rosepine.terminal.color11
      rosepine.terminal.color12
      rosepine.terminal.color13
      rosepine.terminal.color14
      rosepine.terminal.color15
    ];
  };

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
      excludePackages = [ pkgs.xterm ];
    };

    # greetd with tuigreet - lightweight TUI login manager
    # NOTE: Consider trying regreet (GTK greeter) later for a graphical option
    # Themed with rose-pine colors via console.colors (see above)
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-session --asterisks --greeting 'Welcome back!' --cmd Hyprland";
          user = "greeter";
        };
      };
      vt = 1;
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
    mutableUsers = false;
    users.adam = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.adam-password.path;
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
  # fonts.packages = [ ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  environment = {
    # Enable zsh system-wide
    shells = [ pkgs.zsh ];

    etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          zen
          zen-beta
        '';
        mode = "0755";
      };
    };

    # Install system-level packages
    systemPackages = with pkgs; [
      # System services and utilities
      pulseaudio  # CLI tools for pipewire
      networkmanager
      sops
      usbutils
      zip
      unzip
      wget
      lm_sensors
      whois
      dig

      # Bluetooth
      blueman
      bluez
    ];
  };
}
