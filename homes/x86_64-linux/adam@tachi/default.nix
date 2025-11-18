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
      pinentry = pkgs.pinentry-gnome3;
    };

    ghostty = {
      enable = true;
      installPackage = true;
      fontSize = 10;
    };

    doom-emacs.enable = true;
    comic-code-fonts.enable = true;
    desktop.wayland.enable = true;

    lang.elixir.enable = false;
  };

  programs.zsh.shellAliases.rebuild = "sudo nixos-rebuild switch";
  programs.ssh.enable = true;

  home.file."Pictures/wallpaper.png".source = ../../../assets/flake-wallpaper.png;

  home = {
    username = "adam";
    homeDirectory = "/home/adam";
    stateVersion = "25.05";
    packages = with pkgs; [
      # Standalone applications
      bambu-studio
      signal-desktop
      localsend
      inputs.zen-browser.packages."${pkgs.system}".default
    ];
    sessionVariables = {
      # Point to user key in home directory (not /etc/sops/age/)
      # The system module will use /etc/sops/age/keys.txt for boot-time decryption
      SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
    };
  };

  programs.home-manager.enable = true;
}

