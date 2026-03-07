{ pkgs, lib, ... }:
{
  fonts.fontconfig.enable = true;

  bravo = {
    zsh.enable = true;
    bat.enable = true;
    direnv.enable = true;
    devenv.enable = true;
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
    desktop.macos.enable = true;

    lang.elixir.enable = true;

    # Work-specific modules
    dk.litellm.enable = true;
    # dk.jiratui.enable = true;

    # Zen browser with stable profile (prevents new profile on flake updates)
    zen = {
      enable = true;
      profile.path = "adam.Default";
    };
  };

  home = {
    username = "a.zaninovich";
    homeDirectory = "/Users/a.zaninovich";
    stateVersion = "25.05";
    packages = with pkgs; [
      # Work-specific packages
      dotnet-sdk_8
      kubectl
      opencv
      postgresql_16

      # macOS-common packages
      unstable.obsidian
      bravo.pdftomarkdown
      pandoc
      poppler_utils
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
    ];

    sessionVariables = {
      SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
    };
  };

  # sops-nix launchd agent needs /usr/bin in PATH for getconf
  sops.environment.PATH = lib.mkForce "/usr/bin";

  launchd.agents.wheee = {
    enable = true;
    config = {
      ProgramArguments = [ "/usr/bin/caffeinate" "-disu" ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
    };
  };

  programs.ssh = {
    enable = true;
    matchBlocks.rocinante = {
      user = "adam";
      port = 2222;
    };
  };

  programs.home-manager.enable = true;
}
