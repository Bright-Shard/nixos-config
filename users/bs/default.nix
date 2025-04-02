{
  lib,
  pkgs,
  CONSTS,
  ...
}@inputs:

{
  imports = [
    ./theme.nix
    ./programs/dev.nix
    ./programs/hyprland.nix
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
        name = CONSTS.CODE_FONT;
        size = CONSTS.CODE_FONT_SIZE - 4;
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
          text = CONSTS.PGP_KEY;
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
    syncthing = rec {
      enable = true;
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = {
          reclaimed = {
            addresses = [ "tcp://reclaimed.bs" ];
            id = "5WL5JWE-2QQHT4G-RFFE35O-R5WN6C3-OGKIDEN-OBNSQZR-AL57K7Q-2JZOVQ3";
          };
          brilliance = {
            addresses = [ "tcp://brilliance.bs" ];
            id = "CMDCB6R-LD2ONBZ-DLOICW3-34NG2ET-3RLCQCV-7NMJC72-TUSXOSH-3A3Q3AU";
          };
        };
        folders =
          let
            folder = id: {
              enable = true;
              inherit id;
              devices = builtins.attrNames settings.devices;
            };
          in
          {
            "~/.config/home-manager" = folder "pwebb-njeml";
            "~/dev" = folder "jko99-qppnq";
            "~/hacking" = folder "zceck-haczp";
            "~/Documents/texts" = folder "ybnvf-fumyf";
            "~/Photos" = folder "pixel_7_yxha-photos";
            "~/afia" = folder "symzn-kjmpp";
          };
      };
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
