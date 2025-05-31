# Programming-related packages.

{ pkgs, consts, ... }:

{
  home = {
    packages = with pkgs; [
      nixd
      nixfmt-rfc-style
      python313Packages.python-lsp-server

      rustup
      clang

      mold
    ];

    file.".cargo/config.toml".text = ''
      [target.x86_64-unknown-linux-gnu]
      rustflags = ["-C", "link-arg=-fuse-ld=mold"]
    '';
  };

  programs = {
    vscode = {
      enable = true;
      profiles.default.extensions = with pkgs.vscode-extensions; [ ms-vsliveshare.vsliveshare ];
    };
    zed-editor = {
      enable = true;
      extensions = [
        "nix"
        "toml"
        "log"
        "swift"
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
        ui_font_family = consts.codeFont;
        ui_font_size = consts.codeFontSize;
        buffer_font_family = consts.codeFont;
        buffer_line_height = "standard";
        buffer_font_size = consts.codeFontSize;
        soft_wrap = "bounded";
        load_direnv = "shell_hook";
        tab_bar.show = false;
        file_scan_exclusions = [ ];
        inlay_hints.enabled = true;
        edit_predictions.mode = "subtle";
      };
    };
    git = {
      enable = true;
      userName = "BrightShard";
      userEmail = "brightshard@brightshard.dev";
      ignores = [
        # Files created by Syncthing that shouldn't be committed
        ".stfolder"
        ".sync_*.db"
        ".stignore"
      ];
      signing = {
        signByDefault = true;
        format = "openpgp";
        key = consts.pgpKeyGpgId;
      };
      extraConfig = {
        init = {
          defaultBranch = "main";
        };
        safe.directory = [ "/etc/nixos" ];
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
