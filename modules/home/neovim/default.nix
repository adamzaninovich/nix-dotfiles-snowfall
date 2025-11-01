{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.bravo.neovim;
in
{
  options.bravo.neovim = with types; {
    enable = mkEnableOption "neovim";
  };

  # todo: build this out and have it clone my nvim repo
  config = mkIf cfg.enable {
    home.packages = [ ];
    programs.neovim = {
      enable = true;
    };
    home.sessionVariables = {
      EDITOR = "nvim";
    };
  };
}
