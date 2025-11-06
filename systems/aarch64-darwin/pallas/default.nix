{ pkgs, ... }:

# Pallas - Work macOS laptop
# Shared defaults are auto-applied via modules/darwin/macos-defaults

{
  system.primaryUser = "a.zaninovich";
  networking.hostName = "pallas";
  networking.computerName = "pallas";

  users.users."a.zaninovich" = {
    home = "/Users/a.zaninovich";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEo1NeINAvhbxEuhy/JPMs5gkgsyQfw4LBfKrBTvL4YX openpgp:0xA99A403B"
    ];
  };
}
