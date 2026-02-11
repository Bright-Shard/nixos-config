let
  crux = import ../../crux.nix;
in
with crux.DEPS;
[
  (import ./bs.nix)
  nix-ros-overlay.overlays.default
]
