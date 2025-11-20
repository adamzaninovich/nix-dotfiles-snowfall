{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.bravo.doom-emacs;

  doomConfigDir = "${config.xdg.configHome}/doom";
  doomEmacsDir = "${config.xdg.configHome}/emacs";
  doomBinDir = "${doomEmacsDir}/bin";
  doomNeedsInstallMarker = "${doomConfigDir}/.doom-needs-install";
  doomNeedsSyncMarker = "${doomConfigDir}/.doom-needs-sync";
  doomLastSyncFile = "${doomConfigDir}/.doom-last-sync";

  # Repository URLs
  doomConfigRepo = "https://github.com/adamzaninovich/doom-emacs-config.git";
  doomEmacsRepo = "https://github.com/doomemacs/doomemacs.git";
in
{
  options.bravo.doom-emacs = with types; {
    enable = mkEnableOption "Emacs with Doom";

    autoSync = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Automatically run doom sync when changes are detected in the config
        or when Emacs-related packages are updated.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable doom-fonts module (decrypts on activation)
    bravo.doom-fonts.enable = true;

    home.packages = with pkgs; [
      # Platform-specific Emacs builds
      (if pkgs.stdenv.isDarwin then
        # macOS: Custom build with patches for Sequoia compatibility
        (emacs30.override {
          withNativeCompilation = false; # Required for macOS Sequoia 15.4+ due to security restrictions
          withTreeSitter = true;
          withWebP = true;
          withSQLite3 = true;
        }).overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            (pkgs.fetchpatch {
              url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-30/round-undecorated-frame.patch";
              sha256 = "uYIxNTyfbprx5mCqMNFVrBcLeo+8e21qmBE3lpcnd+4=";
            })
            (pkgs.fetchpatch {
              url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-30/system-appearance.patch";
              sha256 = "3QLq91AQ6E921/W9nfDjdOUWR8YVsqBAT/W9c1woqAw=";
            })
            (pkgs.fetchpatch {
              url = "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/refs/heads/master/patches/emacs-28/fix-window-role.patch";
              sha256 = "sha256-+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
            })
          ];
        })
      else
        # Linux: PGTK for proper Wayland support (fixes blurry text)
        emacs30.override {
          withPgtk = true;
          withTreeSitter = true;
          withWebP = true;
          withSQLite3 = true;
        }
      )

      # Fonts
      nerd-fonts.symbols-only
      # Comic Code fonts are installed via bravo.comic-code-fonts module

      # Core dependencies (required by Doom)
      ripgrep # rg - hard dependency for file searches
      fd # faster alternative to find

      # Build tools (for compiling packages like vterm)
      cmake
      gnumake
      libtool

      # Language-specific tools
      jq # JSON processing
      pandoc # Markdown preview and conversion
      nixfmt-rfc-style # Nix formatting
      shellcheck # Shell script linting
      rustup # Rust

      # Web development tools
      html-tidy # HTML formatting
      nodePackages.stylelint # CSS linting
      nodePackages.js-beautify # JS/CSS/HTML formatting
    ];

    # Add doom to PATH
    home.sessionPath = [ "${doomBinDir}" ];

    # Set environment variables
    home.sessionVariables = {
      DOOMDIR = doomConfigDir;
    };

    # Activation script to set up Doom Emacs configuration
    home.activation.doomEmacs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      # Function to handle Git clone operations with error handling
      clone_repo() {
        local repo="$1"
        local target_dir="$2"
        local depth_flag="$3"

        echo "Cloning $repo to $target_dir..."
        if ! $DRY_RUN_CMD ${pkgs.git}/bin/git clone $depth_flag "$repo" "$target_dir"; then
          echo "Failed to clone $repo. Check your network connection or repository URL."
          return 1
        fi
        return 0
      }
      
      # Function to set up secrets
      setup_secrets() {
        local config_dir="$1"
        
        if [ -f "$config_dir/secret.example.el" ] && [ ! -f "$config_dir/secret.el" ]; then
          echo "Setting up Doom Emacs secrets..."
          $DRY_RUN_CMD cp "$config_dir/secret.example.el" "$config_dir/secret.el"
          $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i 's/My Name/Adam Zaninovich/g' "$config_dir/secret.el"
          $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i 's/some-email@example.com/adam.zaninovich@gmail.com/g' "$config_dir/secret.el"
          echo "Secrets configured successfully"
        fi
      }
      
      # Function to create marker files
      create_marker() {
        local marker_file="$1"
        local message="$2"
        
        echo "$message"
        $DRY_RUN_CMD touch "$marker_file"
      }
      
      # Main installation logic
      if [ ! -d "${doomConfigDir}" ]; then
        echo "Setting up Doom Emacs configuration..."
        
        # Clone the configuration repository
        if ! clone_repo "${doomConfigRepo}" "${doomConfigDir}" ""; then
          exit 1
        fi
        
        # Clone Doom Emacs if it doesn't exist
        if [ ! -d "${doomEmacsDir}" ]; then
          if ! clone_repo "${doomEmacsRepo}" "${doomEmacsDir}" "--depth 1"; then
            exit 1
          fi
        fi
        
        # Set up secrets
        setup_secrets "${doomConfigDir}"
        
        # Install Doom Emacs (defer sync until after activation)
        if [ ! -f "${doomBinDir}/doom" ]; then
          create_marker "${doomNeedsInstallMarker}" "Installing Doom Emacs on next shell session..."
        else
          create_marker "${doomNeedsSyncMarker}" "Doom Emacs already installed, will sync on next shell session"
        fi
        
        echo "Doom Emacs setup complete!"
      else
        echo "Doom Emacs config already exists at ${doomConfigDir}"

        ${lib.optionalString cfg.autoSync ''
          # Check if we need to sync based on recent changes
          if [ -f "${doomBinDir}/doom" ]; then
            SHOULD_SYNC=0

            # Check if there have been changes to the config since last sync
            if [ -d "${doomConfigDir}/.git" ] && ${pkgs.git}/bin/git -C "${doomConfigDir}" status --porcelain | grep -v '\.doom-' | grep -q .; then
              create_marker "${doomNeedsSyncMarker}" "Changes detected in Doom config, will sync on next shell session"
              SHOULD_SYNC=1
            else
              # Check if any emacs packages were updated
              if [ -f "${doomLastSyncFile}" ]; then
                # Check if any Emacs or Doom related packages have been updated since last sync
                for PKG_PATH in /nix/store/*-emacs* /nix/store/*-doom* /nix/store/*-elixir*; do
                  if [ -e "$PKG_PATH" ] && [ "$PKG_PATH" -nt "${doomLastSyncFile}" ]; then
                    create_marker "${doomNeedsSyncMarker}" "Detected updated Emacs-related packages, will sync on next shell session"
                    SHOULD_SYNC=1
                    break
                  fi
                done

                if [ "$SHOULD_SYNC" -eq 0 ]; then
                  echo "No changes affecting Doom detected, skipping sync"
                fi
              else
                # First run or no last sync timestamp
                create_marker "${doomNeedsSyncMarker}" "No previous sync timestamp found, will sync on next shell session"
                SHOULD_SYNC=1
              fi
            fi

            # If we should sync, update the last sync timestamp
            if [ "$SHOULD_SYNC" -eq 1 ]; then
              # Update the last sync timestamp (will be used after sync completes)
              date +%s > "${doomLastSyncFile}"
            fi
          fi
        ''}
      fi
    '';

    # Shell initialization to handle deferred doom setup
    programs.zsh.initContent = lib.mkMerge [
      (lib.mkOrder 800 ''
        # Auto-setup Doom Emacs if needed
        if [[ -f "${doomNeedsInstallMarker}" ]]; then
          echo "Setting up Doom Emacs..."
          "${doomBinDir}/doom" install --no-fonts
          rm -f "${doomNeedsInstallMarker}"
          # Update last sync timestamp
          date +%s > "${doomLastSyncFile}"
        ${lib.optionalString cfg.autoSync ''
        elif [[ -f "${doomNeedsSyncMarker}" ]]; then
          echo "Syncing Doom Emacs..."
          "${doomBinDir}/doom" sync
          rm -f "${doomNeedsSyncMarker}"
          # Update last sync timestamp
          date +%s > "${doomLastSyncFile}"
        ''}
        fi
      '')
    ];
  };
}
