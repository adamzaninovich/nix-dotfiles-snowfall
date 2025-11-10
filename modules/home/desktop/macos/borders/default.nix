{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.bravo.desktop.macos.borders;
in
{
  options.bravo.desktop.macos.borders = {
    enable = mkEnableOption "JankyBorders for window borders";
  };

  config = mkIf cfg.enable {
    # Remove the hand-written plist and README
    home.file."Library/LaunchAgents/com.user.borders.plist".enable = false;
    home.file.".config/borders/README.md".enable = false;
    home.file.".local/bin/reload-borders".enable = false;
  };
}
