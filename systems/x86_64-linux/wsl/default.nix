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

  # Docker Desktop bind mount health check
  # Docker Desktop maps WSL bind mounts through an intermediary translation layer.
  # After engine restarts (e.g. Docker Desktop updates), these mappings can go stale -
  # containers keep running but see empty directories instead of the real host paths.
  # This service checks bind mount health on boot and force-recreates if broken.
  # Runs at WSL boot. Manual trigger: sudo systemctl restart docker-bind-mount-fix
  # TODO: if boot-time checks aren't sufficient, add a systemd path unit watching
  # /var/run/docker.sock to detect mid-session Docker Desktop restarts.
  systemd.services.docker-bind-mount-fix = {
    description = "Fix stale Docker Desktop bind mounts";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      export PATH="/usr/bin:$PATH"

      # Wait for Docker Desktop to be available (up to 60s)
      for i in $(seq 1 30); do
        docker info >/dev/null 2>&1 && break
        sleep 2
      done

      if ! docker info >/dev/null 2>&1; then
        echo "Docker not available after 60s, skipping"
        exit 0
      fi

      needs_recreate=false

      # Check bind mount health using proxy container as canary
      if docker ps --format '{{.Names}}' | grep -q '^proxy$'; then
        MARKER=".mount-check-$$"
        echo "ok" > "/opt/stacks/ai/proxy/data/$MARKER"
        RESULT=$(docker exec proxy cat "/data/$MARKER" 2>/dev/null) || true
        rm -f "/opt/stacks/ai/proxy/data/$MARKER"

        if [ "$RESULT" != "ok" ]; then
          echo "Bind mounts are stale, recreating stacks..."
          needs_recreate=true
        else
          echo "Bind mounts are healthy"
        fi
      else
        echo "Proxy container not running, recreating stacks..."
        needs_recreate=true
      fi

      if [ "$needs_recreate" = true ]; then
        docker compose -f /opt/dockge/compose.yaml up -d --force-recreate
        docker compose -f /opt/stacks/ai/compose.yaml up -d --force-recreate
        echo "Stacks recreated with fresh bind mounts"
      fi
    '';
  };

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
      # Don't accept TERM from SSH clients - use the shell's default instead
      # This prevents terminals like Ghostty from overriding TERM with their own values
      extraConfig = ''
        AcceptEnv LANG LC_*
      '';
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
      kmod
      usbutils
      unzip
      python3
    ];
  };
}
