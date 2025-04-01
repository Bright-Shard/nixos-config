# Programming-related packages.

{ pkgs, CONSTS, ... }:

{
  home.packages = with pkgs; [
    zed-editor
    nixd
    nixfmt-rfc-style
    rustup
  ];

  programs = {
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
        ui_font_family = CONSTS.CODE_FONT;
        ui_font_size = CONSTS.CODE_FONT_SIZE;
        buffer_font_family = CONSTS.CODE_FONT;
        buffer_line_height = "standard";
        buffer_font_size = CONSTS.CODE_FONT_SIZE;
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
        key = CONSTS.PGP_KEY_ID;
      };
      extraConfig = {
        init = {
          defaultBranch = "main";
        };
      };
    };
  };
}
