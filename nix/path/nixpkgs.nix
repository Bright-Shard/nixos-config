# Now `import <nixpkgs> {}` will return our nixpkgs with overlays already
# applied.

{ ... }:
let
  crux = import ../../crux.nix;
in
crux.DEPS.nixpkgs
