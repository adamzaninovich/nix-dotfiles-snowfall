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

    # Use activation script to write profiles.ini as a REAL file (not symlink)
    # Zen needs to write to profiles.ini on startup, so it can't be a read-only symlink
    # We reset it on each activation to remove any [Install...] sections that would
    # lock the profile to a specific nix store path (install ID)
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

      # Write profiles.ini as a real file (Zen needs to write to it)
      run cp "${profilesIni}" "$PROFILES_INI"
      run chmod 644 "$PROFILES_INI"

      # Clear installs.ini to prevent install ID locking
      run rm -f "$INSTALLS_INI"

      verboseEcho "Zen Browser: configured profile '${cfg.profile.name}' at '${cfg.profile.path}'"
    '';
  };
}
