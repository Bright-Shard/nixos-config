# Catppuccin themes :D

{ pkgs, ... }:

{
  catppuccin = {
    enable = true;
    flavor = "mocha";
  };
  gtk.enable = true;
  qt = {
    enable = true;
    # Catppuccin replaces the kvantum theme
    style.name = "kvantum";
    platformTheme.name = "kvantum";
  };
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.hyprcursor;
    name = "Hyprcursor";
    size = 16;
  };
}
