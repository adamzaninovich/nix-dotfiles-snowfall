{ lib, config, pkgs, osConfig, ... }:

let
  cfg = config.bravo.comic-code-fonts;
  secretPath = osConfig.sops.secrets.comic-code-fonts.path;
in
{
  options.bravo.comic-code-fonts = {
    enable = lib.mkEnableOption "Comic Code Nerd Font installation from encrypted sources";
  };

  config = lib.mkIf cfg.enable {
    home.activation.comic-code-fonts = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      # Use macOS font directory on Darwin, Linux convention on Linux
      ${if pkgs.stdenv.isDarwin then ''
        FONT_DIR="$HOME/Library/Fonts/comic-code"
      '' else ''
        FONT_DIR="$HOME/.local/share/fonts/comic-code"
      ''}
      SECRET_PATH="${secretPath}"

      echo "Installing Comic Code fonts from encrypted source..."
      rm -rf "$FONT_DIR"
      mkdir -p "$FONT_DIR"
      PATH="${pkgs.gzip}/bin:$PATH" ${pkgs.gnutar}/bin/tar -xzf "$SECRET_PATH" -C "$FONT_DIR"

      ${lib.optionalString pkgs.stdenv.isLinux ''
        ${pkgs.fontconfig}/bin/fc-cache -f "$FONT_DIR"
      ''}
    '';
  };
}
