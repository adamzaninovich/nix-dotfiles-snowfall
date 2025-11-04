{ lib, config, ... }:

let
  cfg = config.bravo.sops;
in
{
  options.bravo.sops = {
    keyFile = lib.mkOption {
      type = lib.types.path;
      default = "/Users/adam/.config/sops/age/keys.txt";
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
        sshKeyPaths = [];  # Don't import SSH keys
      };

      # Don't import GPG or additional SSH keys
      gnupg.sshKeyPaths = [];

      secrets.comic-code-fonts = {
        sopsFile = ../../../secrets/comic-code-fonts.tar.gz;
        format = "binary";
        mode = "0444";
        path = "/var/lib/secrets/comic-code-fonts";
      };
    };
  };
}
