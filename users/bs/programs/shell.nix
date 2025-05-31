{ consts, pkgs, ... }:

{
  home.packages = with pkgs; [
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
  ];

  programs = {
    zsh = {
      enable = true;
      dotDir = ".config/zsh";
      history.path = "/dev/null";
      shellAliases = { };
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
    };

    kitty = {
      enable = true;
      font = {
        name = consts.codeFont;
        size = consts.codeFontSize - 7;
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
