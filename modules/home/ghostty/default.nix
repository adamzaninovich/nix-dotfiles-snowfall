{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.bravo.ghostty;
in
{
  options.bravo.ghostty = with types; {
    enable = mkEnableOption "Ghostty terminal";
    ghostty.installPackage = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install the Ghostty package via nixpkgs";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals cfg.installPackage [
      pkgs.ghostty
    ];

    programs.ghostty = {
      enable = true;
      package = if config.ghostty.installPackage then pkgs.ghostty else null;
      enableZshIntegration = true;
      settings = {
        theme = if pkgs.stdenv.isLinux then "rose-pine-moon" else "Rose Pine Moon";
        font-family = "ComicCode Nerd Font Medium";
        font-size = 14;

        window-padding-x = 4;

        macos-titlebar-style = "transparent";
        macos-titlebar-proxy-icon = "hidden";
        macos-icon = "paper";

        mouse-hide-while-typing = true;
        background-opacity = 0.9;
        background-blur-radius = 20;

        keybind = [
          "shift+enter=text:\\n"
          "ctrl+enter=text:\\n"
        ];
      };
    };
  };
}

