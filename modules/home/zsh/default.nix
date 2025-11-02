{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.bravo.zsh;
  zshAliases = import ./aliases.nix { inherit config lib pkgs; };
in
{
  options.bravo.zsh = with types; {
    enable = mkEnableOption "Enable zsh configuration";
  };

  config = {
    home = {
      packages = with pkgs; [
        bottom
        tree
        eza
        neofetch
      ];
      sessionVariables = {
        PATH = "$HOME/.dotnet/tools:$HOME/.local/bin:$PATH";
        CDPATH = "$HOME:$HOME/projects";
      };
    };

    programs.command-not-found.enable = true;

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };

    programs.zsh = lib.mkMerge [
      {
        enable = cfg.enable;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        defaultKeymap = "emacs";

        plugins = [
          {
            name = "zsh-completions";
            src = pkgs.zsh-completions;
            file = "share/zsh/site-functions";
          }
          {
            name = "fzf-tab";
            src = pkgs.zsh-fzf-tab;
            file = "share/fzf-tab/fzf-tab.plugin.zsh";
          }
        ];

        completionInit = ''
          autoload -U compinit && compinit

          # use git completions for g alias
          compdef g=git

          # Completion styling
          zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
          zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
          zstyle ':completion:*' menu no
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
        '';

        initContent =
          let
            zshConfigEarlyInit = lib.mkOrder 500 ''
              # Clear screen and remove last login message
              # printf '\33c\e[3J'
            '';

            zshConfig = lib.mkOrder 1000 ''
              # Interactive Comments
              setopt interactivecomments

              # History bindings
              bindkey '^p' history-search-backward
              bindkey '^n' history-search-forward

              # Setup GPG SSH agent
              export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
            '';
          in
          lib.mkMerge [
            zshConfigEarlyInit
            zshConfig
          ];
      }
      zshAliases.programs.zsh
    ];

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = false;

        format = "[󱓞](bold bright-pink) $directory $character";
        right_format = "$all";

        character = {
          success_symbol = "[](bold bright-yellow)";
          error_symbol = "[](bold bright-red)";
          vicmd_symbol = "[ ](bold bright-green)";
        };

        cmd_duration = {
          show_notifications = false;
          format = "[ 󰗎 $duration](bold bright-yellow)";
        };

        battery = {
          format = " [$symbol$percentage]($style)";
          display = [
            {
              threshold = 20;
              style = "bold bright-red";
            }
          ];
        };

        username = {
          format = "[  $user]($style) ";
          disabled = false;
          show_always = false;
          style_user = "bold bright-yellow";
          style_root = "bold bright-red";
        };

        hostname = {
          ssh_only = true;
          format = "[󱓞 $hostname]($style) ";
          style = "bold bright-red";
        };

        directory = {
          read_only = "  ";
          format = "[$path]($style)[$read_only]($read_only_style)";
          style = "bold bright-blue";
          truncation_length = 1;
        };

        git_branch = {
          symbol = " ";
          format = " [$symbol$branch]($style)";
          style = "bold bright-green";
          truncation_length = 35;
        };

        git_status = {
          format = "([$all_status$ahead_behind]($style))";
          style = "bold bright-yellow";
        };

        elixir = {
          symbol = "";
          format = " [$symbol]($style)";
          style = "bold bright-purple";
        };

        erlang = {
          symbol = " ";
          format = " [$symbol]($style)";
          style = "bold bright-red";
        };

        rust = {
          symbol = " ";
          format = " [$symbol]($style)";
          style = "bold bright-red";
        };

        nodejs = {
          symbol = " ";
          format = " [$symbol]($style)";
        };

        ruby = {
          symbol = " ";
          format = " [$symbol]($style)";
          style = "bold bright-red";
        };

        python = {
          symbol = " ";
          format = " [$symbol]($style)";
          style = "bold bright-yellow";
        };

        package = {
          symbol = "󰏗 ";
          disabled = true;
        };

        aws.symbol = " ";
        conda.symbol = " ";
        dart.symbol = " ";
        docker_context = {
          symbol = " ";
          disabled = true;
        };
        elm.symbol = " ";
        golang = {
          symbol = " ";
          format = " [$symbol($version)]($style)";
        };
        haskell.symbol = " ";
        hg_branch.symbol = " ";
        java.symbol = " ";
        julia.symbol = " ";
        memory_usage.symbol = "󰍛 ";
        nim.symbol = " ";
        nix_shell = {
          symbol = " ";
          format = " [$symbol$state]($style)";
        };
        perl.symbol = " ";
        php.symbol = " ";
        swift.symbol = " ";
      };
    };
  };
}
