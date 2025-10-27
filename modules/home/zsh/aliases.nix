{ config, lib, pkgs, ... }:
{
  programs.zsh.shellAliases = {
    # Vim stuff
    vi = "vim -N";

    # Git aliases
    gb = "git branch";

    # Shell
    c = "clear";
    cd = ">/dev/null cd"; # don't print when changing via CDPATH
    ".." = "cd ..";
    rm = "rm -v"; # Verbose rms
    mv = "mv -v"; # Verbose moves
    cp = "cp -v"; # Verbose copies

    diff = "diff --color -u";

    # Conditional aliases that depend on available commands
    gotop = lib.mkIf (pkgs ? gotop) "gotop -p";
    cat = lib.mkIf (pkgs ? bat) "bat";

    # LS aliases - conditional on eza availability (explicit commands)
    ls = lib.mkIf (pkgs ? eza) "eza --git --grid";
    l = lib.mkIf (pkgs ? eza) "eza --git --long";
    la = lib.mkIf (pkgs ? eza) "eza --git --long --all";
    tree = lib.mkIf (pkgs ? eza) "eza --git --tree";

    zipr = "zip -r"; # zip a dir

    # Configuration shortcuts
    vconf = "nvim ~/.config/nvim/init.lua";
    # gconf = "nvim ~/.config/snowfall/homes/modules/ghostty.nix && home-manager switch";
    # pconf = "nvim ~/.config/snowfall/homes/modules/starship.nix && home-manager switch";
    # zconf = "nvim ~/.config/snowfall/homes/modules/zsh.nix && home-manager switch";
    # nconf = "nvim ~/.config/snowfall/homes/a.zaninovich.nix && home-manager switch";
    # cnc = "pushd ~/.config/snowfall && claude; popd";

    more = "less";

    # Other
    top10 = "history | awk '{a[\\$2]++}END{for(i in a){print a[i] \" \" i}}' | sort -rn | head";
    tails = "tail -f";
  };

  programs.zsh.initContent = lib.mkMerge [
    # Basic utility functions
    (lib.mkOrder 600 ''
      # Usage: if under-min-version $minimum_version $actual_version; then echo "oh no"; fi
      function under-min-version() {
        min=$1
        current=$2
        test "$min" != "$(echo "$min $current" | tr ' ' '\n' | sort -V | head -n1)"
      }

      function plural() {
        if [[ $2 -eq 1 || $2 -eq -1 ]]; then
          echo ''${1}
        else
          if [[ -n $3 ]]; then
            echo ''${1}''${3}
          else
            echo ''${1}s
          fi
        fi
      }
    '')

    # String formatters and utility functions
    (lib.mkOrder 700 ''
      # string formatters
      if [[ -t 1 ]]; then
        tty_escape() { printf "\033[%sm" "$1"; }
      else
        tty_escape() { :; }
      fi
      tty_mkbold() { tty_escape "1;$1"; }
      tty_underline="$(tty_escape "4;39")"
      tty_blue="$(tty_mkbold 34)"
      tty_yellow="$(tty_mkbold 33)"
      tty_green="$(tty_mkbold 32)"
      tty_red="$(tty_mkbold 31)"
      tty_bold="$(tty_mkbold 39)"
      tty_reset="$(tty_escape 0)"

      shell_join() {
        local arg
        printf "%s" "$1"
        shift
        for arg in "$@"; do
          printf " "
          printf "%s" "''${arg// /\ }"
        done
      }

      ohai() {
        printf "''${tty_blue}==>''${tty_bold} %s''${tty_reset}\n" "$(shell_join "$@")"
      }

      bullet() {
        printf "''${tty_yellow} ● ''${tty_bold} %s''${tty_reset}\n" "$(shell_join "$@")"
      }

      error() {
        printf "''${tty_red}ERROR:''${tty_bold} %s''${tty_reset}\n" "$(shell_join "$@")"
      }
    '')

    # Utility functions
    (lib.mkOrder 750 ''
      colors() {
        # This echoes a bunch of color codes to the terminal to demonstrate what's
        # available. Each line is the color code of one forground color, out of 17
        # (default + 16 escapes), followed by a test use of that color on all nine
        # background colors (default + 8 escapes).

        local text='  ●●●  ' # The test text
        echo -e "                 40m     41m     42m     43m     44m     45m     46m     47m"
        for foreground in '    m' '   1m' '  30m' '1;30m' '  31m' '1;31m' \
                          '  32m' '1;32m' '  33m' '1;33m' '  34m' '1;34m' \
                          '  35m' '1;35m' '  36m' '1;36m' '  37m' '1;37m'
        do
          local fgcode=''${foreground// /}
          echo -en " $foreground \033[$fgcode$text"
          for bgcode in 40m 41m 42m 43m 44m 45m 46m 47m; do
            echo -en "$EINS \033[$fgcode\033[$bgcode$text\033[0m";
          done
          echo
        done
        echo
      }

      set-cursor() {
        case "$@" in
          "blinking block")
            printf '\e[1 q'
            ;;
          *block)
            printf '\e[2 q'
            ;;
          "blinking underscore")
            printf '\e[3 q'
            ;;
          *underscore)
            printf '\e[4 q'
            ;;
          "blinking bar")
            printf '\e[5 q'
            ;;
          *bar)
            printf '\e[6 q'
            ;;
          *)
            echo $"Usage: set-cursor {blinking|steady|} {block|underscore|bar}"
        esac
      }

      fix-cursor() {
        set-cursor underscore
      }

      reset-gpg() {
        gpgconf --launch gpg-agent
        gpg-connect-agent updatestartuptty /bye
      }

      export-gpg-to() {
        local remote="$1"

        if [[ -z "$remote" ]]; then
          error "Usage: export-gpg-to user@host"
          return 1
        fi

        ohai "Exporting GPG keys..."

        # Export keys to temp files
        local tmpdir=$(mktemp -d)
        gpg --export --armor > "$tmpdir/gpg-public.asc"
        gpg --export-secret-keys --armor > "$tmpdir/gpg-private.asc"
        gpg --export-ownertrust > "$tmpdir/gpg-trust.txt"

        ohai "Copying keys to $remote..."
        scp "$tmpdir/gpg-public.asc" "$tmpdir/gpg-private.asc" "$tmpdir/gpg-trust.txt" "$remote:"

        ohai "Cleaning up local temp files..."
        rm -rf "$tmpdir"

        ohai "Importing keys on remote..."
        ssh "$remote" "gpg --import ~/gpg-private.asc && gpg --import ~/gpg-public.asc && gpg --import-ownertrust ~/gpg-trust.txt && rm ~/gpg-public.asc ~/gpg-private.asc ~/gpg-trust.txt"

        ohai "GPG keys successfully exported to $remote"
      }
    '')

    # Editor functions
    (lib.mkOrder 800 ''
      v() {
        if [[ $# -gt 0 ]]
        then
          nvim "$@"
        else
          nvim .
        fi
        # fix-cursor
      }

      e() { emacs -nw "$@" }
    '')

    # Git functions
    (lib.mkOrder 850 ''
      # Opens the current repo's origin remote in a browser
      browse () {
        local first_remote="$(git remote -v 2> /dev/null | grep origin | head -n1)"

        if [[ -z "$first_remote" ]]; then
          error "Either this is not a git repo, or there is no remote origin set"
          return 1
        fi

        if [[ $first_remote =~ 'git@' ]]; then
          # turn git remote into url
          url="$(echo $first_remote | sed -E $'s/[\t @:]+/\\//g' | cut -d / -f 3,4,5)"
          url="https://$url"
          ohai "Opening $url"
          open "$url"
        else
          error "This repo is not using ssh"
          return 1
        fi
      }

      g() {
        if [[ $# -gt 0 ]]; then
          git "$@"
        else
          git status -sb
        fi
      }

      gl() {
        git log --pretty=format:'%Cred%h%Creset -%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'
      }

      gd() {
        tempfile='/tmp/tmp_git_diff.diff'
        git diff "$@" > $tempfile && nvim $tempfile
      }

      ga() {
        if [[ $# -gt 0 ]]
        then
          git add --all "$@"
        else
          git add --all
        fi
      }

      gc() {
        if [[ $# -gt 0 ]]
        then
          git commit -m "$*"
        else
          git commit -v
        fi
      }

      gg_scrub() {
        files=()
        while read -r _status filename; do
          files+=($filename)
        done < <(git status -sb | grep "??")

        echo "Deleting ''${#files[@]} untracked files..."
        echo

        for filename in "''${files[@]}"; do
          rm -vrf "$filename"
        done
      }

      gg_remove() {
        term=$*
        for file in $(git grep -l "$term"); do
          echo "Removing \"$term\" in $file"
          sed -i'.bak' "/$term/d" "$file"
          \rm "''${file}.bak"
        done
      }
    '')

    # Shell utility functions
    (lib.mkOrder 900 ''
      take() {
        local sudo="no"

        if [[ $# -gt 1 ]]
        then
          [[ $1 == "-s" ]] && sudo="yes"
          dir="$2"
        else
          dir="$1"
        fi

        if [[ $sudo == "yes" ]]
        then
          sudo mkdir -p "$dir"
        else
          mkdir -p "$dir"
        fi

        if [[ -d $dir ]]
        then
          cd "$dir" || return
        else
          echo "$dir was not created"
        fi
      }

      function mvp() {
        # Include a / at the end to indicate directory (not filename)
        directory = ""
        destination="$2"
        final_char="$2"; final_char="''${final_char: -1}"
        if [ "$final_char" = "/" ]; then
          directory="$destination"
        else
          directory=$(dirname "$2")
        fi
        echo "dir: '$dir'"
        echo "tmp: '$tmp'"
        if [ -d $directory ]; then
          mv "$@"
        else
          mkdir -p "$directory" && mv "$@"
        fi
      }
    '')

    # Git cleanup functions
    (lib.mkOrder 925 ''
      function git_remove_merged_local_branch() {
        echo "Start removing out-dated local merged branches"
        git branch --merged | egrep -v "(^\*|master|main)" | xargs -I % git branch -d %
        echo "Finish removing out-dated local merged branches"
      }

      # When we use `Squash and merge` on GitHub,
      # `git branch --merged` cannot detect the squash-merged branches.
      # As a result, git_remove_merged_local_branch() cannot clean up
      # unused local branches. This function detects and removes local branches
      # when remote branches are squash-merged.
      #
      # There is an edge case. If you add suggested commits on GitHub,
      # the contents in local and remote are different. As a result,
      # This clean up function cannot remove local squash-merged branch.
      function git_remove_squash_merged_local_branch() {
        echo "Start removing out-dated local squash-merged branches"
        git checkout -q main &&
          git for-each-ref refs/heads/ "--format=%(refname:short)" |
          while read branch; do
            ancestor=$(git merge-base main $branch) &&
              [[ $(git cherry main $(git commit-tree $(git rev-parse $branch^{tree}) -p $ancestor -m _)) == "-"* ]] &&
              git branch -D $branch
          done
        echo "Finish removing out-dated local squash-merged branches"
      }

      # Clean up remote and local branches
      function gg_cleanup() {
        git_remove_merged_local_branch
        git_remove_squash_merged_local_branch
      }
    '')

    # Prompt toggle function
    (lib.mkOrder 940 ''
      toggle-prompt() {
        if [[ "$SIMPLE_PROMPT" == "1" ]]; then
          # Switch back to starship
          unset SIMPLE_PROMPT
          eval "$(starship init zsh)"
        else
          # Switch to simple prompt
          export SIMPLE_PROMPT=1
          PROMPT='> '
          RPROMPT=""
        fi
      }
    '')

    # Configuration shortcuts and functions
    (lib.mkOrder 950 ''
      ea() {
        # Edit aliases and functions in nvim with split view
        nvim -O ~/.config/snowfall/homes/modules/zsh/aliases.nix ~/.config/snowfall/homes/modules/zsh/functions.nix

        # Apply changes with home-manager
        echo "Applying changes with home-manager switch..."
        if home-manager switch; then
          echo "Successfully applied changes!"

          # Re-exec zsh to get the new functions in current shell
          echo "Reloading shell to apply new functions..."
          exec zsh
        else
          echo "home-manager switch failed"
          return 1
        fi
      }

      review() {
        claude "/review $1"
      }

      # claude() {
      #   if [[ $# -gt 0 ]]
      #   then
      #     command claude "$*"
      #   else
      #     command claude
      #   fi
      # }

      setupdb() {
        if [[ -f .local/production_data_packs.sql ]]; then
          mix ecto.drop && mix ecto.create && mix ecto.migrate && PGPASSWORD="postgres" psql -h localhost -U postgres -d fist_dev -c "ALTER TABLE tickets DISABLE TRIGGER ALL;" && PGPASSWORD="postgres" psql -h localhost -U postgres -d fist_dev -f .local/production_data_packs.sql
        fi
      }

    '')

    # Nix build function
    (lib.mkOrder 975 ''
      switch() {
        # Parse options
        local do_pull=false
        while getopts "p" opt; do
          case $opt in
            p)
              do_pull=true
              ;;
            \?)
              error "Invalid option: -$OPTARG"
              return 1
              ;;
          esac
        done

        pushd ~/.config/snowfall > /dev/null

        # Pull if requested
        if $do_pull; then
          # Stash any changes before pulling
          local stashed=false
          if ! git diff-index --quiet HEAD --; then
            ohai "Stashing local changes..."
            git stash push -u -m "switch -p temporary stash" || {
              error "Failed to stash changes"
              popd > /dev/null
              return 1
            }
            stashed=true
          fi

          ohai "Pulling latest changes from git..."
          if ! git pull; then
            error "Git pull failed"
            if $stashed; then
              ohai "Attempting to restore stashed changes..."
              git stash pop
            fi
            popd > /dev/null
            return 1
          fi

          # Restore stashed changes
          if $stashed; then
            ohai "Restoring stashed changes..."
            git stash pop || {
              error "Failed to restore stashed changes - they're in the stash"
              popd > /dev/null
              return 1
            }
          fi
        fi

        # Add changes to git first so nix can see new files
        ohai "Adding changes to git..."
        git add .

        # Detect host type and run appropriate command
        if [[ -d /etc/nixos ]]; then
          # NixOS host
          ohai "Detected NixOS host, running nixos-rebuild..."
          sudo nixos-rebuild switch --flake ~/.config/snowfall
        elif [[ "$(uname)" == "Darwin" ]]; then
          # macOS host with nix-darwin + home-manager
          ohai "Detected macOS host, running darwin-rebuild..."
          sudo darwin-rebuild switch --flake ~/.config/snowfall

          if [[ $? -eq 0 ]]; then
            ohai "Darwin rebuild successful, now running snowfall..."
            # home-manager switch --flake ~/.config/snowfall
          else
            error "Darwin rebuild failed, skipping home-manager"
            return 1
          fi
        else
          # Other Linux distro with home-manager only
          ohai "Detected Linux host, running home-manager..."
          # home-manager switch --flake ~/.config/snowfall
        fi

        popd > /dev/null
      }
    '')
  ];
}
