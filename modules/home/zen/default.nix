{ pkgs, lib, config, inputs, ... }:
with lib;
let
  cfg = config.bravo.zen;

  # macOS puts profiles in Library/Application Support/zen
  # Linux uses ~/.zen
  configDir = if pkgs.stdenv.isDarwin
    then "$HOME/Library/Application Support/zen"
    else "$HOME/.zen";

  # Content for profiles.ini - no [Install...] sections means Zen uses Default profile
  profilesIniContent = ''
    [Profile0]
    Name=${cfg.profile.name}
    IsRelative=1
    Path=Profiles/${cfg.profile.path}
    Default=1

    [General]
    StartWithLastProfile=1
    Version=2
  '';

  profilesIni = pkgs.writeText "zen-profiles.ini" profilesIniContent;

  # Python script to compute Firefox install ID hash
  # Firefox uses CityHash64 on the UTF-16-LE encoded path to Contents/MacOS
  computeInstallId = pkgs.writeScript "compute-zen-install-id" ''
    #!${pkgs.python3}/bin/python3
    import sys
    from clickhouse_cityhash.cityhash import CityHash64

    if len(sys.argv) != 2:
        print("Usage: compute-zen-install-id <path-to-app>", file=sys.stderr)
        sys.exit(1)

    app_path = sys.argv[1]
    # Firefox hashes the Contents/MacOS directory path
    macos_path = f"{app_path}/Contents/MacOS"
    # Encode as UTF-16-LE and compute CityHash64
    path_bytes = macos_path.encode("utf-16-le")
    hash_value = CityHash64(path_bytes)
    # Output as uppercase hex
    print(f"{hash_value:016X}")
  '';

  # Wrapper to run the script with the cityhash dependency
  computeInstallIdWrapper = pkgs.writeShellScript "compute-zen-install-id-wrapper" ''
    export PYTHONPATH="${pkgs.python3Packages.clickhouse-cityhash}/${pkgs.python3.sitePackages}"
    exec ${computeInstallId} "$@"
  '';
in
{
  options.bravo.zen = with types; {
    enable = mkEnableOption "Zen browser with stable profile management";

    profile = {
      name = mkOption {
        type = str;
        default = "default";
        description = "Display name of the profile in Zen's profile manager";
      };

      path = mkOption {
        type = str;
        description = ''
          The profile directory name (e.g., "xmffz6yt.Default (release)").
          Find your existing profile in ~/Library/Application Support/zen/Profiles/
          and use the folder name that contains your data (bookmarks, history, etc).
        '';
        example = "xmffz6yt.Default (release)";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      inputs.zen-browser.packages.${pkgs.system}.default
    ];

    # Use activation script to write profiles.ini and installs.ini
    # We compute the Firefox install ID from the current zen app path and
    # pre-populate installs.ini to point to our profile, preventing Zen
    # from creating a new profile on each flake update
    home.activation.zenProfiles = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      CONFIG_DIR="${configDir}"
      PROFILES_INI="$CONFIG_DIR/profiles.ini"
      INSTALLS_INI="$CONFIG_DIR/installs.ini"

      # Ensure config directory exists
      run mkdir -p "$CONFIG_DIR/Profiles"

      # Remove any existing symlinks (from previous home-manager generations)
      if [ -L "$PROFILES_INI" ]; then
        run rm "$PROFILES_INI"
      fi
      if [ -L "$INSTALLS_INI" ]; then
        run rm "$INSTALLS_INI"
      fi

      # Find the zen app path from the wrapper script
      ZEN_WRAPPER="${inputs.zen-browser.packages.${pkgs.system}.default}/bin/zen"
      ZEN_APP_PATH=$(${pkgs.gnugrep}/bin/grep -o '/nix/store/[^"]*\.app' "$ZEN_WRAPPER" | head -1)

      if [ -n "$ZEN_APP_PATH" ] && [ -d "$ZEN_APP_PATH" ]; then
        # Compute install ID using CityHash64 on the Contents/MacOS path (UTF-16-LE encoded)
        INSTALL_ID=$(${computeInstallIdWrapper} "$ZEN_APP_PATH")

        if [ -n "$INSTALL_ID" ]; then
          # Write profiles.ini with BOTH the profile AND the install section
          # Zen requires both profiles.ini [Install...] and installs.ini to match
          cat > "$PROFILES_INI" << EOF
[Profile0]
Name=${cfg.profile.name}
IsRelative=1
Path=Profiles/${cfg.profile.path}
Default=1

[General]
StartWithLastProfile=1
Version=2

[Install$INSTALL_ID]
Default=Profiles/${cfg.profile.path}
Locked=1
EOF
          run chmod 644 "$PROFILES_INI"

          # Write installs.ini with the computed install ID pointing to our profile
          cat > "$INSTALLS_INI" << EOF
[$INSTALL_ID]
Default=Profiles/${cfg.profile.path}
Locked=1
EOF
          run chmod 644 "$INSTALLS_INI"
          verboseEcho "Zen Browser: configured install ID $INSTALL_ID -> profile '${cfg.profile.path}'"
        else
          verboseEcho "Zen Browser: WARNING - could not compute install ID, using default profiles.ini"
          run cp "${profilesIni}" "$PROFILES_INI"
          run chmod 644 "$PROFILES_INI"
          run rm -f "$INSTALLS_INI"
        fi
      else
        verboseEcho "Zen Browser: WARNING - could not find zen app path, using default profiles.ini"
        run cp "${profilesIni}" "$PROFILES_INI"
        run chmod 644 "$PROFILES_INI"
        run rm -f "$INSTALLS_INI"
      fi
    '';
  };
}
