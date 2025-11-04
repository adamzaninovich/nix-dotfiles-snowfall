{ pkgs, inputs, ... }:
{
  fonts.fontconfig.enable = true;

  bravo = {
    zsh.enable = true;
    bat.enable = true;
    direnv.enable = true;
    neovim.enable = true;
    claude.enable = true;

    gpg = {
      enable = true;
      autostart = true;
      pinentry = pkgs.pinentry_mac;
    };

    ghostty = {
      enable = true;
      installPackage = false; # Install manually on macOS
      fontSize = 14;
    };

    doom-emacs.enable = true;
    comic-code-fonts.enable = true;

    lang.elixir.enable = true;
  };

  programs.ssh.enable = true;

  home = {
    username = "adam";
    homeDirectory = "/Users/adam";
    stateVersion = "25.05";
    packages = with pkgs; [
      # rocinante only
      ntfs3g
      # macOS-specific packages
      age
      sops
      localsend
      coreutils
      coreutils-prefixed
      gawk
      gdu
      gh
      gh-dash
      glibtool
      lazygit
      nodejs_22
      python314
      rustup
      shellcheck
      # shottr
      stow
    ];
  };

  programs.home-manager.enable = true;
}
