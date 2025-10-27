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
      # publicKeys = [
      #   {
      #     source = ./adamzaninovich-public.asc;
      #     trust = 5;
      #   }
      # ];
      # settings = {
      #   throw-keyids = true;
      #   no-autostart = !cfg.autostart;
      # };
      # scdaemonSettings = {
      #   disable-ccid = true;
      # };
    };

    services.gpg-agent = {
      enable = cfg.enable;
      verbose = true;
      enableSshSupport = true;
      enableExtraSocket = cfg.enableExtraSocket;
      enableZshIntegration = config.programs.zsh.enable;
      pinentry.package = cfg.pinentry;

      # Extended cache times for better UX
      defaultCacheTtl = 28800; # 8 hours
      maxCacheTtl = 86400; # 24 hours

      # Expose GPG authentication subkey for SSH
      sshKeys = [
        "CE83B6C2A9B82941FED98562F384045C00C25F25"
        "59B8D2368303B94DFD08394A704284F4466F2D51"
      ];
      # enableScDaemon = true;
      # grabKeyboardAndMouse = false;
    };
  };
}
