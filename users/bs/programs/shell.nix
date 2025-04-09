{ bsUtils, pkgs, ... }:

{
  home = {
    shellAliases = {
      # Clears screen and scrollback, instead of just screen:
      # https://github.com/kovidgoyal/kitty/issues/268#issuecomment-419342337
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
    };

    packages = with pkgs; [
      (writeShellScriptBin "sysupdate" ''
        	sudo nix-channel --update
         sudo nixos-rebuild switch
      '')
      (writeShellScriptBin "docker" ''
        podman "$@"
      '')
    ];
  };

  programs = {
    zsh = {
      enable = true;
      dotDir = ".config/zsh";
      history.path = "/dev/null";
    };
    starship = {
      enable = true;
      enableZshIntegration = true;
    };
    kitty = {
      enable = true;
      font = {
        name = bsUtils.codeFont;
        size = bsUtils.codeFontSize - 7;
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
