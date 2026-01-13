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
  # Firefox uses CityHash64 on the UTF-16-LE encoded path:
  # - macOS: hashes {app_path}/Contents/MacOS
  # - Linux: hashes the directory containing the binary
  computeInstallId = pkgs.writeScript "compute-zen-install-id" ''
    #!${pkgs.python3}/bin/python3
    import sys
    from clickhouse_cityhash.cityhash import CityHash64

    if len(sys.argv) != 2:
        print("Usage: compute-zen-install-id <path>", file=sys.stderr)
        sys.exit(1)

    path = sys.argv[1]
    # Encode as UTF-16-LE and compute CityHash64
    path_bytes = path.encode("utf-16-le")
    hash_value = CityHash64(path_bytes)
    # Output as uppercase hex
    print(f"{hash_value:016X}")
  '';

  # Wrapper to run the script with the cityhash dependency
  computeInstallIdWrapper = pkgs.writeShellScript "compute-zen-install-id-wrapper" ''
    export PYTHONPATH="${pkgs.python3Packages.clickhouse-cityhash}/${pkgs.python3.sitePackages}"
    exec ${computeInstallId} "$@"
  '';

  # Use our signed wrapper on Darwin, upstream package on Linux
  # TODO: Remove zen-browser-temp-signing-fix once upstream fixes the issue
  zenPackage = if pkgs.stdenv.isDarwin
    then pkgs.bravo.zen-browser-temp-signing-fix
    else inputs.zen-browser.packages.${pkgs.system}.default;
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
        type = types.nullOr str;
        default = null;
        description = ''
          The profile directory name containing your data (bookmarks, history, etc).

          macOS: Find in ~/Library/Application Support/zen/Profiles/
                 Example: "xmffz6yt.Default (release)"

          Linux: Find in ~/.zen/ (profiles are at the top level, not in a subdirectory)
                 Example: "abc123xy.Default (release)"

          If not set, Zen is installed without profile management - useful for new
          machines where no profile exists yet.
        '';
        example = "xmffz6yt.Default (release)";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ zenPackage ];

    # Use activation script to write profiles.ini and installs.ini
    # We compute the Firefox install ID from the current zen app path and
    # pre-populate installs.ini to point to our profile, preventing Zen
    # from creating a new profile on each flake update
    #
    # Only runs if profile.path is set - otherwise Zen manages its own profiles
    home.activation.zenProfiles = mkIf (cfg.profile.path != null) (config.lib.dag.entryAfter [ "writeBoundary" ] ''
      CONFIG_DIR="${configDir}"
      PROFILES_INI="$CONFIG_DIR/profiles.ini"
      INSTALLS_INI="$CONFIG_DIR/installs.ini"

      # Platform-specific profile path and app extraction
      ${if pkgs.stdenv.isDarwin then ''
        # macOS: profiles in Profiles/ subdirectory
        PROFILE_PATH="Profiles/${cfg.profile.path}"
        run mkdir -p "$CONFIG_DIR/Profiles"
      '' else ''
        # Linux: profiles directly in ~/.zen
        PROFILE_PATH="${cfg.profile.path}"
        run mkdir -p "$CONFIG_DIR"
      ''}

      # Remove any existing symlinks (from previous home-manager generations)
      if [ -L "$PROFILES_INI" ]; then
        run rm "$PROFILES_INI"
      fi
      if [ -L "$INSTALLS_INI" ]; then
        run rm "$INSTALLS_INI"
      fi

      ${if pkgs.stdenv.isDarwin then ''
        # macOS: directly use the app path from zenPackage (not from wrapper script)
        # The wrapper script may contain stale paths from the upstream package
        HASH_PATH="${zenPackage}/Applications/Zen Browser (Beta).app/Contents/MacOS"
      '' else ''
        # Linux: Use zen-beta binary which contains the wrapper info
        ZEN_WRAPPER="${zenPackage}/bin/zen-beta"
      ''}

      ${if pkgs.stdenv.isDarwin then ''
        : # HASH_PATH already set above
      '' else ''
        # Linux: Zen hashes the lib/zen-bin-<version> directory
        # Extract the wrapped binary path from the wrapper script
        ZEN_WRAPPED=$(${pkgs.binutils-unwrapped}/bin/strings "$ZEN_WRAPPER" | ${pkgs.gnugrep}/bin/grep -o '/nix/store/[^"]*/bin/\.zen-beta-wrapped' | head -1)
        if [ -n "$ZEN_WRAPPED" ]; then
          # Resolve symlink to get the actual binary location
          # e.g., /nix/store/.../lib/zen-bin-1.17.15b/zen
          ZEN_REAL=$(readlink -f "$ZEN_WRAPPED" 2>/dev/null)
          if [ -n "$ZEN_REAL" ]; then
            # Hash the parent directory (lib/zen-bin-<version>)
            HASH_PATH=$(dirname "$ZEN_REAL")
          else
            HASH_PATH=""
          fi
        else
          HASH_PATH=""
        fi
      ''}

      if [ -n "$HASH_PATH" ]; then
        # Compute install ID using CityHash64 on the path (UTF-16-LE encoded)
        INSTALL_ID=$(${computeInstallIdWrapper} "$HASH_PATH")

        if [ -n "$INSTALL_ID" ]; then
          # Write profiles.ini with BOTH the profile AND the install section
          # Zen requires both profiles.ini [Install...] and installs.ini to match
          cat > "$PROFILES_INI" << EOF
[Profile0]
Name=${cfg.profile.name}
IsRelative=1
Path=$PROFILE_PATH
Default=1

[General]
StartWithLastProfile=1
Version=2

[Install$INSTALL_ID]
Default=$PROFILE_PATH
Locked=1
EOF
          run chmod 644 "$PROFILES_INI"

          # Write installs.ini with the computed install ID pointing to our profile
          cat > "$INSTALLS_INI" << EOF
[$INSTALL_ID]
Default=$PROFILE_PATH
Locked=1
EOF
          run chmod 644 "$INSTALLS_INI"
          verboseEcho "Zen Browser: configured install ID $INSTALL_ID -> profile '$PROFILE_PATH'"
        else
          verboseEcho "Zen Browser: WARNING - could not compute install ID, using default profiles.ini"
          run cp "${profilesIni}" "$PROFILES_INI"
          run chmod 644 "$PROFILES_INI"
          run rm -f "$INSTALLS_INI"
        fi
      else
        verboseEcho "Zen Browser: WARNING - could not find zen binary path, using default profiles.ini"
        run cp "${profilesIni}" "$PROFILES_INI"
        run chmod 644 "$PROFILES_INI"
        run rm -f "$INSTALLS_INI"
      fi
    '');
  };
}
