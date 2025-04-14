# Environment variables.

with builtins;
{
  NIXOS_OZONE_WL = "1";
  XCURSOR_SIZE = "16";
  QT_QPA_PLATFORM = "wayland";
  QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  PATH = "/home/bs/.cargo/bin:$PATH";
}
# Set fcitx5 as the IME
// (listToAttrs (
  map
    (var: {
      name = var;
      value = "fcitx5";
    })
    [
      "INPUT_METHOD"
      "GTK_IM_MODULE"
      "QT_IM_MODULE"
    ]
))
