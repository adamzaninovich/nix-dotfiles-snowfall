{ lib, config, ... }:

let
  cfg = config.bravo.sops;
in
{
  options.bravo.sops = {
    keyFile = lib.mkOption {
      type = lib.types.path;
      default = "/home/adam/.config/sops/age/keys.txt";
      description = "Path to the sops age key file. Use keys.txt symlink for host-agnostic config.";
    };
  };

  config = {
    sops = {
      defaultSopsFile = ../../../secrets/system-secrets.yaml;
      validateSopsFiles = false;

      age = {
        # Use keys.txt symlink which points to the host-specific key
        keyFile = cfg.keyFile;
      };

      secrets.adam-password = { neededForUsers = true; };

      secrets.comic-code-fonts = {
        sopsFile = ../../../secrets/comic-code-fonts.tar.gz;
        format = "binary";
        mode = "0444";
      };
    };
  };
}
