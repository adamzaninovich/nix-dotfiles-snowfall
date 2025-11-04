{ lib, config, pkgs, osConfig, ... }:

let
  cfg = config.bravo.doom-fonts;
  secretPath = osConfig.sops.secrets.doom-fonts.path;
in
{
  options.bravo.doom-fonts = {
    enable = lib.mkEnableOption "Doom fonts installation from encrypted sources";
  };

  config = lib.mkIf cfg.enable {
    home.activation.doom-fonts = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      FONT_DIR="$HOME/.local/share/fonts/doom-fonts"
      SECRET_PATH="${secretPath}"

      echo "Installing Doom fonts from encrypted source..."
      rm -rf "$FONT_DIR"
      mkdir -p "$FONT_DIR"
      PATH="${pkgs.gzip}/bin:$PATH" ${pkgs.gnutar}/bin/tar -xzf "$SECRET_PATH" -C "$FONT_DIR"

      ${pkgs.fontconfig}/bin/fc-cache -f "$FONT_DIR"
    '';
  };
}
