let
  crux = import ../../crux.nix;
in
with crux;

[
  (import ./bs.nix)
  DEPS.nix-ros-overlay.overlays.default
]
