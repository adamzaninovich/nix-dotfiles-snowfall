{ pkgs, ... }:
{
  bravo = {
    bat.enable = true;
    gpg.enable = true;
    neovim.enable = true;
    zsh.enable = true;
  };

  programs.home-manager.enable = true;

  # Home Manager settings
  home = {
    username = "adam";
    homeDirectory = "/home/adam";
    stateVersion = "25.05";

    packages = with pkgs; [
      # CLI utilities
      curl
      eza
      fd
      jq
      ripgrep
      nixfmt-rfc-style
    ];

    sessionVariables = {
      SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
      # Disable GUI-related variables for headless server
      DISPLAY = "";
    };

    file.".local/bin/backup-ssh" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash

        usage () {
          echo "Usage: backup-ssh (auth|backup|restore|logs|help)"
          echo "  auth    - creates ssh key and authorizes it with Barbapiccola"
          echo "  backup  - backs up ~/docker to Barbapiccola"
          echo "  restore - restores ~/docker from Barbapiccola"
          echo "  logs    - view backup service logs from systemd journal"
          echo "  help    - prints this message"
          echo
          echo "Log command examples:"
          echo "  backup-ssh logs              # View all logs"
          echo "  backup-ssh logs -f           # Follow logs in real-time"
          echo "  backup-ssh logs -n 50        # View last 50 lines"
          echo "  backup-ssh logs --since yesterday"
          echo "  backup-ssh logs -b --since '24 hours ago'"
          echo
          echo "Note: Automated backups are scheduled via systemd timer (docker-backup.timer)"
          echo "      Run 'systemctl status docker-backup.timer' to check status"
        }

        authorize () {
          echo "Generating SSH Keys..."
          if [ -f ~/.ssh/id_ed25519.pub ]; then
            echo "ed25519 key exists"
          else
            ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
            echo "Generated ed25519 key"
          fi

          echo "Adding key to root user"
          sudo cp ~/.ssh/id_ed25519* /root/.ssh/

          echo "Authorizing key with Barbapiccola"
          key=$(cat ~/.ssh/id_ed25519.pub)
          ssh vclab@10.1.1.2 -p 20022 "if [ -z \"\$(grep \"$key\" ~/.ssh/authorized_keys )\" ]; then echo $key >> ~/.ssh/authorized_keys; echo Key authorized; else echo Key already authorized; fi;"
        }

        backup () {
          server="$(hostname)"
          docker_dir="/srv/docker"
          backup_dir="/volume1/Backups/docker/''${server}/docker"

          echo '========================='
          TZ='America/Los_Angeles' date
          echo "Creating directory on nas"
          ssh vclab@10.1.1.2 -p 20022 "mkdir -p $backup_dir"

          echo "Backing up ''${docker_dir} to Barbapiccola:''${backup_dir}"
          sudo rsync -au --partial --delete --exclude="*.pid" "''${docker_dir}/" vclab@10.1.1.2:"$backup_dir"
          echo "Done"
        }

        restore () {
          server="$(hostname)"
          docker_dir="/srv/docker"
          backup_dir="/volume1/Backups/docker/''${server}/docker"

          echo '========================='
          TZ='America/Los_Angeles' date
          echo "Creating local directory"
          sudo mkdir -p "''${docker_dir}"

          echo "Restoring from Barbapiccola:''${backup_dir} to ''${docker_dir}"
          echo "Note: This will NOT delete local files, only copy from backup"
          sudo rsync -au --partial --exclude="*.pid" vclab@10.1.1.2:"$backup_dir/" "''${docker_dir}/"
          echo "Done"
        }

        logs () {
          journalctl -u docker-backup.service "''${@:2}"
        }

        case "$1" in
          auth*)
            authorize
            ;;

          backup)
            backup
            ;;

          restore)
            restore
            ;;

          logs)
            logs "$@"
            ;;

          *)
            usage
            ;;
        esac

      '';
    };
  };
}
