# Programming-related packages.

{ pkgs, bsUtils, ... }:

{
  home.packages = with pkgs; [
    zed-editor
    nixd
    nixfmt-rfc-style
    rustup
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
        restore_on_startup = "none";
        hard_tabs = true;
        tab_size = 3;
        ui_font_family = bsUtils.codeFont;
        ui_font_size = bsUtils.codeFontSize;
        buffer_font_family = bsUtils.codeFont;
        buffer_line_height = "standard";
        buffer_font_size = bsUtils.codeFontSize;
        soft_wrap = "bounded";
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
}
