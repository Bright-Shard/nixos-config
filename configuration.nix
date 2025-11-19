# Global NixOS configuration.
# These settings get applied to all NixOS hosts, but also all containers.

{
  pkgs,
  lib,
  crux,
  specialArgs,
  config,
  NPINS,
  BUILD-META,
  ...
}@args:

let
  inherit (lib) mkMerge mkIf;
in
with crux;

mkMerge [
  # Nix & Nixpkgs
  {
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      elem (lib.getName pkg) [
        "osu-lazer-bin"
        "1password"
        "1password-cli"
        "steam"
        "steam-unwrapped"
        "minecraft-server"
      ];
    nix = {
      settings = {
        experimental-features = [ "nix-command" ];
        trusted-substituters =
          if !config.bs.apple-silicon && BUILD-META.NATIVE-HOST != "brilliance" then
            [
              # Note: This ordering is intentional, we want brilliance to be
              # queried before the main NixOS cache
              # Help NixOS out a lil bit, save them server load
              # Also helps with some packages that my machines compile but
              # NixOS' cache doesn't
              "http://brilliance.bs:5000"
              "https://cache.nixos.org"
            ]
          else
            [ "https://cache.nixos.org" ];
        extra-substituters = mkIf config.bs.apple-silicon [
          "https://nixos-apple-silicon.cachix.org"
        ];
        extra-trusted-public-keys = [
          "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
        ];
      };
      nixPath = [ "nixpkgs=${NPINS.nixpkgs}" ];
    };
    system.stateVersion = config.bs.state-version;
  }

  # Shell settings
  {
    users.defaultUserShell = pkgs.zsh;
    programs.zsh = {
      enable = true;
      histFile = "/dev/null";
    };
    environment.shellAliases = {
      # Clears screen and scrollback, instead of just screen:
      # https://github.com/kovidgoyal/kitty/issues/268#issuecomment-419342337
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
    };
    services.envfs.enable = true;
  }

  # Users and Home Manager
  {
    users = {
      users = {
        # idk why but it complains the root shell is set twice if this is true
        root.useDefaultShell = false;
        bs = {
          isNormalUser = true;
          createHome = false;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = [ KEYS.SSH-PUBLIC ];
        };
      };
    };

    home-manager =
      let
        # Zen browser flake hackily imported in stable Nix
        zen-browser = (import "${NPINS.zen-browser}/flake.nix").outputs {
          self = zen-browser;
          nixpkgs = pkgs;
          home-manager = {
            outPath = NPINS.home-manager;
          };
        };
      in
      {
        useGlobalPkgs = true;
        sharedModules = [
          "${NPINS.catppuccin}/modules/home-manager"
          zen-browser.homeModules.default
          ./users/configuration.nix
        ];
        users = listToAttrs (
          map (username: {
            name = username;
            value = ./users/${username};
          }) (readSubdirs ./users)
        );
        extraSpecialArgs = specialArgs // {
          nixosConfig = config;
        };
      };
  }

  # Packages
  {
    environment.systemPackages = with pkgs; [
      w3m
      bat
      ripgrep
      busybox
      curl
      wget
      jq
      git

      # LSP tools
      nixd
      nixfmt-rfc-style
      package-version-server
    ];
    fonts.packages = with pkgs; [
      nerd-fonts.shure-tech-mono
      noto-fonts
      noto-fonts-lgc-plus
      noto-fonts-cjk-sans
      noto-fonts-monochrome-emoji
      noto-fonts-emoji-blob-bin
    ];
  }
  (mkMerge (map (dirEntry: import ./programs/${dirEntry} args) (attrNames (readDir ./programs))))

  # Security key
  {
    hardware.gpgSmartcards.enable = true;
    environment.etc."u2f-pam.auth" = {
      text = "bs:nW1/4BoE0+W+X5vCidomK6ko+muRb4Nwx36X1pC8k4XHt4v0w+yyMnBgG2L7mnCg13N9G0RXeV6PrpS6Cg1FKQ==,T8dzqEwYdvv36D1dtE/wjMAtlJuG+wdeJRXlfsoSRfFagCUi2GgdqwpwSPNxgIp1vvf0QZ6zp59pM7QOECqZMA==,es256,+presence";
      mode = "0444";
    };
    security.pam.u2f = {
      enable = true;
      settings = rec {
        origin = "pam://brightshard/";
        appid = origin;
        cue = true;
        authfile = "/etc/u2f-pam.auth";
      };
    };
  }

  # Other random shit
  {
    networking = {
      hostName = BUILD-META.HOSTNAME;
      enableIPv6 = false;
    };

    i18n.defaultLocale = "en_US.UTF-8";
    catppuccin = {
      enable = true;
      flavor = THEME.CATPPUCCIN_FLAVOR;
      accent = THEME.CATPPUCCIN_ACCENT;
    };

    documentation.dev.enable = true;
  }
]
