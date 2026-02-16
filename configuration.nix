# Global NixOS configuration.
# These settings get applied to all NixOS hosts, but also all containers.

{
  pkgs,
  crux,
  specialArgs,
  config,
  ...
}:

with crux;

mkMerge [
  # Nix & Nixpkgs
  {
    nix = {
      settings =
        let
          substituters = [
            # Self-hosted x86_64 binary cache
            {
              enable = !config.bs.apple-silicon && HOSTNAME != "brilliance";
              url = "http://brilliance.bs:5000";
              key = "brilliance:MOcBbGMoWZgVPATkKbqr0aKl/62yRX21syYAxtg7yWg=";
            }
            # Binary cache for https://github.com/lopsided98/nix-ros-overlay
            {
              enable = config.bs.ros;
              url = "https://ros.cachix.org";
              key = "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=";
            }
            {
              enable = config.bs.apple-silicon;
              url = "https://nixos-apple-silicon.cachix.org";
              key = "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20=";
            }
          ];
          enabledSubstituters = filter (sub: sub.enable) substituters;
        in
        {
          substituters = map (sub: sub.url) enabledSubstituters;
          trusted-public-keys = map (sub: sub.key) enabledSubstituters;
          experimental-features = [ "nix-command" ];
        };
      nixPath =
        let
          entries = map (replaceStrings [ ".nix" ] [ "" ]) (attrNames (readDir ./nix/path));
        in
        map (entry: "${entry}=${FILESET}/nix/path/${entry}.nix") entries;
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
        root = {
          hashedPassword = "!";
          # idk why but it complains the root shell is set twice if this is true
          useDefaultShell = false;
        };
        bs = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = [ KEYS.SSH-PUBLIC ];
        };
      };
    };

    home-manager = {
      useGlobalPkgs = true;
      sharedModules = [
        DEPS.catppuccin.homeModules.default
        DEPS.zen-browser.homeModules.default
        ./users/all.nix
      ]
      ++ (map (module: ./home-manager/modules/${module}) (attrNames (readDir ./home-manager/modules)));
      users =
        let
          allUsers = readSubdirs ./users;
          users = filter (user: hasAttr user config.users.users) allUsers;
        in
        listToAttrs (
          map (username: {
            name = username;
            value = ./users/${username};
          }) users
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
      zip
      unzip
      curl
      wget
      jq
      git

      # LSP tools
      nixd
      nixfmt
      package-version-server

      # Docs
      man-pages
      man-pages-posix
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
      hostName = HOSTNAME;
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
