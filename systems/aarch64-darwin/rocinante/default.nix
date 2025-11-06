{ pkgs, ... }:

# Rocinante - Personal macOS laptop
# Shared defaults are auto-applied via modules/darwin/macos-defaults

{
  system.primaryUser = "adam";
  networking.hostName = "rocinante";
  networking.computerName = "rocinante";

  users.users.adam = {
    home = "/Users/adam";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEo1NeINAvhbxEuhy/JPMs5gkgsyQfw4LBfKrBTvL4YX openpgp:0xA99A403B"
    ];
  };
}
