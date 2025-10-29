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
      pinentry = pkgs.pinentry-gnome3;
    };

    ghostty = {
      enable = true;
      installPackage = true;
      fontSize = 10;
    };

    lang.elixir.enable = false;
    doom-emacs.enable = false;
  };

  programs.zsh.shellAliases.rebuild = "sudo nixos-rebuild switch";
  programs.ssh.enable = true;

  home.file."Pictures/wallpaper.png".source = ../../../assets/flake-wallpaper.png;

  home ={
    username = "adam";
    homeDirectory = "/home/adam";
    stateVersion = "25.05";
    packages = with pkgs; [
      bambu-studio
      grimblast
      kdePackages.gwenview
      imagemagick
      imv
      pinta
      zoom-us
    ];
  };

  programs.home-manager.enable = true;
}

