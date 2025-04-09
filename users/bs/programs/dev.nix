# Programming-related packages.

{ pkgs, bsUtils, ... }:

{
  home.packages = with pkgs; [
    zed-editor

    nixd
    nixfmt-rfc-style

    rustup
    clang
  ];

  programs = {
    vscode = {
      enable = true;
      profiles.default.extensions = with pkgs.vscode-extensions; [
        ms-vsliveshare.vsliveshare
      ];
    };
    zed-editor = {
      enable = true;
      extensions = [
        "nix"
        "toml"
      ];
      userKeymaps = [
        {
          context = "Terminal";
          bindings = {
            ctrl-shift-t = "workspace::NewTerminal";
          };
        }
      ];
      userSettings = {
        telemetry = {
          diagnostics = true;
          metrics = true;
        };
        languages = {
          Nix = {
            language_servers = [
              "nixd"
              "!nil"
            ];
          };
        };
        ssh_connections = [
          {
            host = "reclaimed.bs";
            projects = [ { paths = [ "/home/bs" ]; } ];
          }
        ];
        restore_on_startup = "none";
        hard_tabs = true;
        tab_size = 3;
        ui_font_family = bsUtils.codeFont;
        ui_font_size = bsUtils.codeFontSize;
        buffer_font_family = bsUtils.codeFont;
        buffer_line_height = "standard";
        buffer_font_size = bsUtils.codeFontSize;
        soft_wrap = "bounded";
        load_direnv = "shell_hook";
        tab_bar.show = false;
      };
    };
    git = {
      enable = true;
      userName = "BrightShard";
      userEmail = "brightshard@brightshard.dev";
      aliases = {
        mm = ''
          		BRANCH=$(git branch --show-current)
               MAIN=$(git branch --points-at origin/HEAD)
               git checkout $MAIN
               git pull
               git checkout $BRANCH
               git merge $MAIN
        '';
      };
      ignores = [
        # Files created by Syncthing that shouldn't be committed
        ".stfolder"
        ".sync_*.db"
        ".stignore"
      ];
      signing = {
        signByDefault = true;
        format = "openpgp";
        key = bsUtils.pgpKeyGpgId;
      };
      extraConfig = {
        init = {
          defaultBranch = "main";
        };
      };
    };
  };

  services = {
    podman = {
      enable = true;
      settings.registries.insecure = [ "docker.io" ];
    };
  };
}
