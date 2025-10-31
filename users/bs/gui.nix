# Home-manager settings that are only applied if the host has `bs.gui` enabled.

{
  crux,
  pkgs,
  config,
  nixosConfig,
  NPINS,
  ...
}:

with crux;
let
  inherit (nixosConfig) bs;
in

{
  home.packages = with pkgs; [
    # WM
    niri
    pwvucontrol
    bemenu
    wl-clipboard

    # Extremely crucial package
    # I'd die without it
    # Seriously, where would the world be
    pipes

    # Apps
    mpv
    krita
    xournalpp
    signal-desktop
    tor-browser
    mullvad-vpn
    mullvad-browser
    monero-gui
    railway-wallet
    obs-studio
    obs-studio-plugins.input-overlay
    ((import NPINS.zen-browser { inherit pkgs; }).default)

    # Utilities
    brightnessctl
    kdePackages.dolphin
    kdePackages.gwenview
    solaar

    # Gaming
    mangohud
    gamemode
    osu-lazer-bin
    prismlauncher
  ];

  # Niri config
  xdg.configFile."niri/config.kdl".text =
    let
      baseCfg = replaceStrings [ "\${MOD}" "\${ALTMOD}" ] [ bs.mod bs.altMod ] (readFile ./apps/niri.kdl);
    in
    baseCfg
    + (concatStringsSep "\n" (
      map (cmd: "spawn-at-startup ${concatStringsSep " " (map (arg: "\"${arg}\"") cmd)}") [
        [
          "${pkgs.fcitx5}/bin/fcitx5"
          "-d"
        ]
        [
          "${pkgs.swaybg}/bin/swaybg"
          "-i"
          "/home/bs/documents/wallpapers/wallpaper"
          "-m"
          "fill"
        ]
      ]
    ))
    + "\nxwayland-satellite { path \"${pkgs.xwayland-satellite}/bin/xwayland-satellite\"; }";

  # Apps managed by home-manager
  programs = {
    waybar = import ./apps/waybar.nix;
    vesktop = import ./apps/vesktop.nix;
    alacritty.enable = true;
  };

  services.playerctld.enable = true;

  gtk = {
    enable = true;
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    gtk3.bookmarks = [
      "file:///home/bs/dev"
      "file:///home/bs/hacking"
      "file:///home/bs/documents"
      "file:///home/bs/downloads"
    ];
  };
  qt = {
    enable = true;
    # Catppuccin replaces the kvantum theme
    style.name = "kvantum";
    platformTheme.name = "kvantum";
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      addons = with pkgs; [ fcitx5-mozc ];
      waylandFrontend = true;
    };
  };
}
