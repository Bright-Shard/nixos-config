# Catppuccin themes :D

{ config, ... }:

{
  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "flamingo";
    # Creates a CSS file for Waybar styling which we can then
    # import for the eww config
    waybar.mode = "createLink";
    gtk.enable = true;
    gtk.gnomeShellTheme = true;
    cursors.enable = true;
  };
  gtk = {
    enable = true;
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    gtk3.bookmarks = [
      "file:///home/bs/dev"
      "file:///home/bs/hacking"
    ];
  };
  qt = {
    enable = true;
    # Catppuccin replaces the kvantum theme
    style.name = "kvantum";
    platformTheme.name = "kvantum";
  };
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    size = 16;
  };
}
