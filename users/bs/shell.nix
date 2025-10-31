{ pkgs, crux, ... }:

with crux;

{
  home = {
    shellAliases = {
      dbg-waybar = "GTK_DEBUG=interactive waybar";
    };
    packages = with pkgs; [
      (writeShellScriptBin "docker" ''
        podman "$@"
      '')

      # Allows you to run "git mm" to merge the current branch with master
      (writeShellScriptBin "git-mm" ''
        branch=$(git branch --show-current)
        main=$(git branch -r | grep origin/HEAD | cut -d "/" -f 3)
        echo "Merging '$main' into '$branch'..."
        git checkout $main
        git pull
        git checkout $branch
        git merge $main
      '')

      # Did you know you can use xargs to trim leading and trailing whitespace???
      # only in bash ig
      (writeShellScriptBin "git-size-matters" ''
        git add --all
        size=$(git diff --staged --shortstat)
        getField() {
          echo "$size" | cut -d ',' -f $1 | cut -d '(' -f 1 | xargs
        }
        files=$(getField 1)
        insertions=$(getField 2)
        deletions=$(getField 3)
        echo -e "$files, \x1B[32m+$insertions\x1B[0m, \x1B[31m-$deletions\x1B[0m"
        git reset HEAD > /dev/null
      '')
    ];
  };

  programs = {
    starship = {
      enable = true;
      enableZshIntegration = true;
    };

    kitty = {
      enable = true;
      font = {
        name = THEME.CODE_FONT;
        size = 11;
      };
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      config.whitelist = {
        prefix = [ "~/dev" ];
        exact = [
          "~/hacking/.envrc"
          "~/afia/.envrc"
        ];
      };

      nix-direnv.enable = true;
    };
  };
}
