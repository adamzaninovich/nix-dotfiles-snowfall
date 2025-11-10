{ config, lib, pkgs, inputs, ... }:

let
  rosepine = lib.bravo.rose_pine;
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.05";

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

  nixpkgs.config = {
    allowUnfree = true;
  };

  # Boot configuration - GRUB 2 boot loader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Networking configuration
  networking.hostName = "sgate";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.1.1.4";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "10.1.1.1";
  networking.nameservers = [
    "10.1.1.8"
    "10.1.1.9"
  ];
  networking.enableIPv6 = false;

  # Time zone and locale
  time.timeZone = "America/Los_Angeles";
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
    # OpenSSH
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        # KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
      # Don't accept TERM from SSH clients - use the shell's default instead
      # This prevents terminals like Ghostty from overriding TERM with their own values
      extraConfig = ''
        AcceptEnv LANG LC_*
      '';
    };
  };

  users = {
    mutableUsers = false;
    users.adam = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.adam-password.path;
      extraGroups = [ "wheel" "docker" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEo1NeINAvhbxEuhy/JPMs5gkgsyQfw4LBfKrBTvL4YX openpgp:0xA99A403B"
      ];
    };
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Services
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Dockge Docker manager
  # bravo.dockge.enable = true;

  # systemd.services."docker-create-networks" = {
  #   description = "Ensure Docker networks exist";
  #   after = [ "docker.service" ];
  #   wants = [ "docker.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig.Type = "oneshot";

  #   path = [ pkgs.docker pkgs.coreutils ];

  #   script = ''
  #     if ! docker network inspect solgate >/dev/null 2>&1; then
  #       docker network create solgate
  #     fi
  #   '';
  # };

  # Docker backup service and timer
  # systemd.services.docker-backup = {
  #   description = "Backup docker data to NAS";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = "adam";
  #     ExecStart = "/home/adam/.local/bin/backup-ssh backup";
  #   };
  # };

  # systemd.timers.docker-backup = {
  #   description = "Run docker backup daily";
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnCalendar = "05:00";
  #     Persistent = true;
  #   };
  # };

  # Enable passwordless sudo
  security.sudo.extraRules = [
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

  environment = {
    # Enable zsh system-wide
    shells = [ pkgs.zsh ];

    # Install system-level packages
    systemPackages = with pkgs; [
      age
      sops
      docker-compose
      # System services and utilities
      zip
      unzip
      wget
      whois
      dig
    ];
  };
}
