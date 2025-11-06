{ config, lib, ... }:
with lib;
let
  cfg = config.bravo.ssh;
in
{
  options.bravo.ssh = {
    enable = mkEnableOption "SSH client configuration";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;

      matchBlocks = {
        "*" = {
          extraOptions = {
            # Set TERM to xterm-256color for all SSH connections
            # This ensures proper terminal capabilities on remote systems
            "SetEnv" = "TERM=xterm-256color";
          };
        };
      };
    };
  };
}
