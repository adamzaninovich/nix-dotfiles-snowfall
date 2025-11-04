{ lib, config, pkgs, osConfig, ... }:

let
  cfg = config.bravo.doom-fonts;
  # Path to encrypted tarball in the flake
  encryptedFonts = ../../../secrets/doom-fonts.tar.gz;
  # Age key path from system config
  ageKeyFile = osConfig.sops.age.keyFile;
in
{
  options.bravo.doom-fonts = {
    enable = lib.mkEnableOption "Doom fonts installation from encrypted sources";
  };

  config = lib.mkIf cfg.enable {
    home.activation.doom-fonts = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      # Use macOS font directory on Darwin, Linux convention on Linux
      ${if pkgs.stdenv.isDarwin then ''
        FONT_DIR="$HOME/Library/Fonts/doom-fonts"
      '' else ''
        FONT_DIR="$HOME/.local/share/fonts/doom-fonts"
      ''}
      ENCRYPTED_FILE="${encryptedFonts}"
      AGE_KEY="${ageKeyFile}"

      echo "Installing Doom fonts from encrypted source..."
      rm -rf "$FONT_DIR"
      mkdir -p "$FONT_DIR"

      # Decrypt and extract in one pipeline
      SOPS_AGE_KEY_FILE="$AGE_KEY" ${pkgs.sops}/bin/sops -d "$ENCRYPTED_FILE" | \
        PATH="${pkgs.gzip}/bin:$PATH" ${pkgs.gnutar}/bin/tar -xzf - -C "$FONT_DIR"

      ${lib.optionalString pkgs.stdenv.isLinux ''
        ${pkgs.fontconfig}/bin/fc-cache -f "$FONT_DIR"
      ''}
    '';
  };
}
