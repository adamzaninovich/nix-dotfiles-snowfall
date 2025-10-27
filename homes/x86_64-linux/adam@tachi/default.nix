{ pkgs, inputs, ... }:
{
  fonts.fontconfig.enable = true;

  bravo = {
    zsh.enable = true;
    bat.enable = true;

    gpg = {
      enable = true;
      autostart = true;
      pinentry = pkgs.pinentry-gnome3;
    };

    ghostty = {
      enable = true;
      installPackage = true;
    };

    lang.elixir.enable = false;
    doom-emacs.enable = false;
    neovim.enable = false;
    claude.enable = false;
  };

  programs.zsh.shellAliases.rebuild = "sudo nixos-rebuild switch";
  programs.ssh.enable = true;
  programs.doom-emacs.enable = true;

  # Host-specific Ghostty overrides
  programs.ghostty.settings = {
    font-size = 12;  # Override the default 14
  };

  home ={
    username = "adam";
    homeDirectory = "/home/adam";
    stateVersion = "25.05";
    packages = with pkgs; [
      # inputs.comic-code.packages.${pkgs.system}.default
    ];
  };

  programs.home-manager.enable = true;
};

