{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.bravo.gpg;
in
{
  options.bravo.gpg = with types; {
    enable = mkEnableOption "gpg";

    autostart = mkOption {
      type = bool;
      default = true;
      description = "whether to auto start agent";
    };

    enableExtraSocket = mkOption {
      type = bool;
      default = false;
      description = "Whether to enable extra socket";
    };

    # set this to pinentry_mac on Darwin
    pinentry = mkPackageOption pkgs "pinentry" { default = "pinentry-gnome3"; };
  };

  config = mkIf cfg.enable {
    programs.gpg = {
      enable = true;
    };

    services.gpg-agent = {
      enable = cfg.enable;
      enableSshSupport = true;
      enableZshIntegration = config.programs.zsh.enable;
      pinentry.package = cfg.pinentry;

      # Extended cache times for better UX
      defaultCacheTtl = 28800; # 8 hours
      maxCacheTtl = 86400; # 24 hours

      # Disable grab on macOS to allow pinentry-mac keychain integration
      # grabKeyboardAndMouse = !pkgs.stdenv.isDarwin;

      # Expose GPG authentication subkey for SSH
      sshKeys = [
        "8B6927D71151F843BFE79F0D3417726F43192AD2"
      ];
    };
  };
}
