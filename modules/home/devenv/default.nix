{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.bravo.devenv;
in
{
  options.bravo.devenv = with types; {
    enable = mkEnableOption "Fast, Declarative, Reproducible and Composable Developer Environments using Nix";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      devenv
    ];
  };
}
