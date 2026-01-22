# Global home-manager settings for all users.

{
  crux,
  config,
  pkgs,
  nixosConfig,
  ...
}:

with crux;
let
  inherit (nixosConfig) bs;
in

{
  home = {
    packages = with pkgs; [
      nixd
      lldb
    ];
    stateVersion = bs.state-version;
  };

  catppuccin = {
    enable = true;
    flavor = THEME.CATPPUCCIN_FLAVOR;
    accent = THEME.CATPPUCCIN_ACCENT;
    cursors.enable = bs.gui;
  };

  programs = {
    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      history.path = "/dev/null";
    };

    zed-editor = {
      enable = bs.gui;
      extensions = [
        "nix"
        "toml"
        "log"
        "swift"
        "zig"
        "sql"
        "kdl"
      ];
      userKeymaps =
        let
          mod = replaceStrings [ "+" ] [ "-" ] bs.altMod;
        in
        [
          {
            bindings = {
              # Editor movement
              "${mod}-w" = "workspace::ActivatePaneUp";
              "${mod}-s" = "workspace::ActivatePaneDown";
              "${mod}-a" = "workspace::ActivatePaneLeft";
              "${mod}-d" = "workspace::ActivatePaneRight";
              "${mod}-t" = "workspace::NewTerminal";

              # Panels
              "ctrl-alt-o" = "projects::OpenRecent";
              "${mod}-k" = "command_palette::Toggle";
              "${mod}-q" = "pane::CloseAllItems";
              "${mod}-p up" = "pane::SplitUp";
              "${mod}-p down" = "pane::SplitDown";
              "${mod}-p left" = "pane::SplitLeft";
              "${mod}-p right" = "pane::SplitRight";
              "${mod}-p g" = "git_panel::ToggleFocus";
              "${mod}-p f" = "workspace::NewSearch";
              "${mod}-p d" = "diagnostics::Deploy";
              "${mod}-p p" = "project_panel::ToggleFocus";
              "${mod}-p o" = "outline::Toggle";
              "${mod}-p l" = "workspace::ToggleLeftDock";
              "${mod}-p r" = "workspace::ToggleRightDock";

              # "go" keybinds
              "${mod}-g d" = "editor::GoToDefinition";
              "${mod}-g s d" = "editor::GoToDefinitionSplit";
              "${mod}-g i" = "editor::GoToImplementation";
              "${mod}-g s i" = "editor::GoToImplementationSplit";
              "${mod}-g n" = "editor::GoToNextDocumentHighlight";
              "${mod}-g shift-n" = "editor::GoToPreviousDocumentHighlight";
              "${mod}-g b" = "pane::GoBack";
              "${mod}-g f" = "pane::GoForward";
              "${mod}-g e" = "editor::GoToDiagnostic";
              "${mod}-g shift-e" = "editor::GoToPreviousDiagnostic";

              # Excerpt management
              "${mod}-e o" = "editor::OpenExcerpts";
              "${mod}-e up" = "editor::ExpandExcerptsUp";
              "${mod}-e down" = "editor::ExpandExcerptsDown";

              # Cursor management
              "${mod}-c m" = "editor::SelectAllMatches";
            };
          }
        ];
      userSettings = rec {
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
            hard_tabs = false;
            tab_size = 2;
          };
          YAML = {
            hard_tabs = false;
            tab_size = 2;
          };
        };
        disable_ai = true;
        restore_on_startup = "none";
        hard_tabs = true;
        tab_size = 3;
        ui_font_family = THEME.CODE_FONT;
        ui_font_size = 18;
        buffer_font_family = ui_font_family;
        buffer_font_size = ui_font_size;
        buffer_line_height = "standard";
        soft_wrap = "bounded";
        load_direnv = "shell_hook";
        tab_bar.show = false;
        file_scan_exclusions = [ ];
        inlay_hints.enabled = false;
        edit_predictions.mode = "subtle";
        search = {
          seed_search_query_from_cursor = "selection";
          use_smartcase_search = true;
        };
        lsp = {
          rust-analyzer.initialization_options.check.command = "clippy";
        };
        language_models.ollama.api_url = "http://hibana.bs:11434";
      };
    };

    gpg = {
      enable = true;
      publicKeys = [
        {
          text = KEYS.PGP-PUBLIC;
          trust = 5;
        }
      ];
    };
    git = {
      enable = true;
      ignores = [
        # Syncthing files
        ".stfolder"
        ".sync_*.db"
        ".stignore"
      ];
      settings = {
        user = {
          name = "BrightShard";
          email = "brightshard@brightshard.dev";
        };
        init = {
          defaultBranch = "main";
        };
        safe.directory = [ "/etc/nixos" ];
        push.autoSetupRemote = true;
      };
      signing = {
        signByDefault = true;
        format = "openpgp";
        key = KEYS.PGP-GPG-ID;
      };
    };
  };

  xdg.userDirs =
    let
      home = config.home.homeDirectory;
    in
    {
      enable = true;
      createDirectories = true;
      desktop = null;
      documents = "${home}/documents";
      download = "${home}/downloads";
      music = "${home}/media";
      pictures = "${home}/media";
      videos = "${home}/media";
      templates = "${home}/media";
      publicShare = null;
    };
}
