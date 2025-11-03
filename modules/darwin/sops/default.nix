{ ... }:

{
  sops = {
    defaultSopsFile = ../../../secrets/system-secrets.yaml;
    validateSopsFiles = false;

    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    secrets.adam-password = { };

    secrets.comic-code-fonts = {
      sopsFile = ../../../secrets/comic-code-fonts.tar.gz;
      format = "binary";
      mode = "0444";  # World-readable
    };
  };
}
