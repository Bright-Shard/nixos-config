{
  lib,
  pkgs,
  bsUtils,
  ...
}@inputs:

let
  isNixFile =
    with builtins;
    file: (stringLength file) > 4 && (substring (stringLength file - 4) 4 file) == ".nix";
in
{
  imports =
    with builtins;
    [
      ./theme.nix
      "${fetchTarball "https://github.com/catppuccin/nix/archive/main.tar.gz"}/modules/home-manager"
    ]
    ++ (map (file: ./programs/${file}) (filter isNixFile (attrNames (readDir ./programs))));

  manual.html.enable = true;
  nixpkgs.config = {
    allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "osu-lazer-bin"
        "vscode"
        "vscode-extension-ms-vsliveshare-vsliveshare"
      ];
    permittedInsecurePackages = [
      # https://github.com/krille-chan/fluffychat/issues/1258
      "fluffychat-linux-1.25.1"
      "olm-3.2.16"
    ];
  };

  home = {
    username = "bs";
    homeDirectory = "/home/bs";
    stateVersion = "24.11";

    packages =
      with pkgs;
      with inputs;
      with builtins;
      [
        # Apps
        vesktop
        signal-desktop
        fluffychat

        # Utilities
        fastfetch
        nmap
        socat
        jq
        obs-studio
        obs-studio-plugins.input-overlay
        tailscale

        # Games
        osu-lazer-bin
        prismlauncher

        # Misc
        font-manager
        fcitx5
        fcitx5-mozc

        # System Monitors
        nvtopPackages.amd
        bottom
      ]
      # Custom packages
      ++ (map (file: pkgs.callPackage ./pkgs/${file} { }) (
        filter isNixFile (attrNames (readDir ./pkgs))
      ));

    sessionVariables = import ./env.nix;
  };

  programs = {
    home-manager.enable = true;
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
