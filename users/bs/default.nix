{
  lib,
  pkgs,
  bsUtils,
  ...
}@inputs:

{
  imports = [
    ./theme.nix
    ./programs/dev.nix
    ./programs/hyprland.nix
    ./programs/syncthing.nix
    "${fetchTarball "https://github.com/catppuccin/nix/archive/main.tar.gz"}/modules/home-manager"
  ];

  manual.html.enable = true;
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "osu-lazer-bin"
      "vscode"
      "vscode-extension-ms-vsliveshare-vsliveshare"
    ];

  home = {
    username = "bs";
    homeDirectory = "/home/bs";
    stateVersion = "24.11";

    packages =
      with pkgs;
      with inputs;
      [
        # Apps
        (callPackage ./pkgs/zen.nix { })
        vesktop
        fastfetch

        # Games
        osu-lazer-bin

        # Dev
        tailscale
        podman

        # Misc
        font-manager
        fcitx5
        fcitx5-mozc

        # Monitors
        nvtopPackages.amd
        bottom

        # Shell Scripts
        (writeShellScriptBin "sysupdate" ''
          	sudo nix-channel --update
            sudo nixos-rebuild switch
            home-manager switch
        '')
      ];

    shellAliases = {
      docker = "podman";
      # Clears screen and scrollback, instead of just screen:
      # https://github.com/kovidgoyal/kitty/issues/268#issuecomment-419342337
      clear = "printf '\033[2J\033[3J\033[1;1H'";
    };

    sessionVariables = import ./env.nix;
  };

  programs = {
    home-manager.enable = true;
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
        size = bsUtils.codeFontSize - 4;
      };
    };
    hyprlock = {
      enable = true;
      settings = {
        general.hide_cursor = true;
      };
    };
    gpg = {
      enable = true;
      publicKeys = [
        {
          text = bsUtils.pgpKey;
          trust = 5;
        }
      ];
    };
  };

  services = {
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableZshIntegration = true;
      pinentryPackage = pkgs.pinentry-qt;
      sshKeys = [ "AC30BE46A5E3A3662BA677BCA5999525DB625466" ];
    };
    ollama = {
      enable = true;
      acceleration = "rocm";
      environmentVariables = {
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
      };
    };
  };
}
