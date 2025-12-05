{
  pkgs,
  crux,
  nixosConfig,
  NPINS,
  ...
}:

with crux;

{
  imports = [ ./shell.nix ] ++ (if nixosConfig.bs.gui then [ ./gui.nix ] else [ ]);

  config = {
    manual.html.enable = true;

    home = {
      username = "bs";
      homeDirectory = "/home/bs";
      packages = with pkgs; [
        # Utilities
        fastfetch
        ffmpeg
        yt-dlp
        android-tools
        nmap
        dig
        zip

        # Misc
        font-manager

        # System Monitors
        nvtopPackages.amd
        bottom

        # Dev Tooling
        rustup
        clang
        mold
        socat
        jq
        inotify-tools
        tokei
      ];

      sessionVariables = {
        NIXOS_OZONE_WL = "1";
        XCURSOR_SIZE = "12";
        QT_QPA_PLATFORM = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        PATH = "/home/bs/.cargo/bin:$PATH";
      }
      # Set fcitx5 as the IME
      // (listToAttrs (
        map
          (var: {
            name = var;
            value = "fcitx5";
          })
          [
            "INPUT_METHOD"
            "QT_IM_MODULE"
          ]
      ));
    };

    programs = {
      home-manager.enable = true;
    };

    services = {
      gpg-agent = {
        enable = true;
        enableSshSupport = true;
        enableZshIntegration = true;
        pinentry.package = pkgs.pinentry-qt;
        sshKeys = [ "AC30BE46A5E3A3662BA677BCA5999525DB625466" ];
      };
      podman = {
        enable = true;
        settings.registries.search = [
          "docker.io"
        ];
      };
    };
  };
}
