{ pkgs, inputs, ... }:
{
  fonts.fontconfig.enable = true;

  bravo = {
    zsh.enable = true;
    bat.enable = true;
    neovim.enable = true;
    claude.enable = true;

    gpg = {
      enable = true;
      autostart = true;
      pinentry = pkgs.pinentry_mac;
    };

    ghostty = {
      enable = true;
      installPackage = false;  # Install via Homebrew or manually on macOS
      fontSize = 13;
    };

    doom-emacs.enable = true;
    comic-code-fonts.enable = true;

    lang.elixir.enable = false;
  };

  programs.zsh.shellAliases.rebuild = "darwin-rebuild switch --flake ~/.config/snowfall#rocinante";
  programs.ssh.enable = true;

  home = {
    username = "adam";
    homeDirectory = "/Users/adam";
    stateVersion = "25.05";
    packages = with pkgs; [
      # macOS-specific packages
    ];
  };

  programs.home-manager.enable = true;
}
