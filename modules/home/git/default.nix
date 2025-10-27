{ pkgs, ... }:

{
  # home.packages = [
  #   pkgs.git-extras
  # ];

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
    };
    extensions = with pkgs; [ gh-dash ];
  };

  programs.git = {
    enable = true;
    userName = "Adam Zaninovich";
    userEmail = "adam.zaninovich@gmail.com";

    signing = {
      key = "29E932E5BE1B8445";
      signByDefault = true;
    };

    extraConfig = {
      gpg.program = "${pkgs.gnupg}/bin/gpg";
      init.defaultBranch = "main";
      help.autocorrect = 1;
      color.ui = "auto";
      push.default = "simple";
      branch.sort = "-committerdate";
      pull.rebase = false;
      "diff \"lisp\"".xfuncname = "^(\\(.*)$";
      "diff \"org\"".xfuncname = "^(\\*+ +.*)$";
      merge.conflictstyle = "diff3";
      # --
      color.branch = {
        current = "green";
        local = "default";
        remote = "magenta";
        upstream = "blue";
        plain = "default";
      };
      log.abbrevCommit = true;
      core = { editor = "nvim"; };
      diff = { algorithm = "histogram"; };
      status = { showUntrackedFiles = "all"; };
      blame = { date = "relative"; };
      push.autoSetupRemote = true;
      checkout = { defaultRemote = "origin"; };
      url."git@github.com:adam.zaninovich/".insteadOf = "me:";
      url."git@github.com:".insteadOf = "gh:";
    };

    aliases = {
      co = "checkout";
      undo-commit = "reset --soft HEAD^";
      unstage = "reset HEAD";
      c = "commit -v";
      b = "branch";
      amend = "commit --amend";
      ammend = "commit --amend";
    };

    attributes = [
      "*.lisp  diff=lisp"
      "*.el    diff=lisp"
      "*.org   diff=org"
    ];

    ignores = [
      ".DS_Store"
      ".idea"
      "*.log"
      "tmp/"
      "config-emacs-elixir-format.exs"
      ".envrc"
      ".direnv"
    ];
  };
}
