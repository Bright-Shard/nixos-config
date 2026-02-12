let
  crux = import ../../crux.nix;
in
with crux;

let
  npins = import ./npins;
  flake-compat = import ./flake-compat;
  mapped-flakes = mapAttrs (
    k: v:
    if pathExists "${v}/flake.nix" then
      (flake-compat {
        src = v;
        follows = DEPS;
      })
    else
      v
  ) npins;
in
mapped-flakes
// {
  inherit npins;
}
