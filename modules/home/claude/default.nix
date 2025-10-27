{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.bravo.claude;
in
{
  options.bravo.claude = with types; {
    enable = mkEnableOption "Claude Code AI assistant";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.unstable.claude-code
    ];
  };
}
