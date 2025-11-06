{ pkgs, ... }:
{
  # Enable fontconfig for proper font rendering
  fonts.fontconfig.enable = true;

  # Bravo modules
  bravo = {
    bat.enable = true;
    ssh.enable = true;
    claude.enable = true;
    comic-code-fonts.enable = true;
    direnv.enable = true;
    doom-emacs.enable = true;
    doom-fonts.enable = true;
    git.enable = true;
    gpg.enable = true;
    lang.elixir.enable = true;
    neovim.enable = true;
    zsh.enable = true;
  };

  # Shell configuration
  programs.zsh.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake ~/.config/snowfall#wsl";
    rebuild-test = "sudo nixos-rebuild test --flake ~/.config/snowfall#wsl";
  };

  programs.home-manager.enable = true;

  # Home Manager settings
  home = {
    username = "adam";
    homeDirectory = "/home/adam";
    stateVersion = "25.05";

    packages = with pkgs; [
      # WSL utilities
      wslu

      # Development tools
      neovim
      autoconf
      automake
      cmake
      gnumake
      gcc

      # CLI utilities
      curl
      eza
      fd
      jq
      ripgrep
      nixfmt-rfc-style
      fontconfig
    ];
  };
}
