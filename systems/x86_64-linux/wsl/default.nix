{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  # WSL Configuration
  wsl = {
    enable = true;
    defaultUser = "adam";
    startMenuLaunchers = true;
    useWindowsDriver = true; # WSLg/OpenGL
    docker-desktop.enable = true; # WSL Docker integration

    wslConf = {
      network.hostname = "wsl";
      network.generateResolvConf = false;
      interop.enabled = true;
    };
  };

  # Custom nameservers (since we disabled generateResolvConf)
  networking.nameservers = [
    "10.1.1.8"
    "10.1.1.9"
  ];

  # Nix Configuration
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

  # System Settings
  system.stateVersion = "25.05";
  time.timeZone = "America/Los_Angeles";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";

  # Services
  services = {
    openssh = {
      enable = true;
      # Allow systemd to start the service automatically
      startWhenNeeded = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };

  # Programs
  programs = {
    ssh.startAgent = true;
    zsh.enable = true;
  };

  # User Configuration
  users = {
    mutableUsers = false;
    users.adam = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.adam-password.path;
      extraGroups = [
        "wheel"
        "docker"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEo1NeINAvhbxEuhy/JPMs5gkgsyQfw4LBfKrBTvL4YX openpgp:0xA99A403B"
      ];
    };
  };

  # Security
  security.sudo = {
    # Preserve SSH_AUTH_SOCK for agent forwarding
    extraConfig = ''
      Defaults env_keep += "SSH_AUTH_SOCK"
    '';

    # Enable passwordless sudo
    extraRules = [
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

  # Environment
  environment = {
    shells = [ pkgs.zsh ];

    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";
    };

    # System-level packages
    systemPackages = with pkgs; [
      age
      sops
      wget
      whois
      dig
    ];
  };
}
