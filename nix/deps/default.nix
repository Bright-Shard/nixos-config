let
  crux = import ../../crux.nix;
in
with crux;

let
  npins = import ./npins;
  flake-compat = import ./flake-compat nixpkgs-flake.legacyPackages.${currentSystem};
  imported-flakes = mapAttrs (
    k: v:
    if pathExists "${v}/flake.nix" then
      (flake-compat {
        src = v;
        follows = imported-flakes;
      })
    else
      v
  ) npins;

  # We have to import nixpkgs carefully to not cause infinite recursion:
  # - flake-compat needs access to nixpkgs
  # - which is used in our nixpkgs overlay
  # - which is needed to import nixpkgs
  #
  # We solve this by first importing the nixpkgs flake and using this to
  # 'bootstrap' our overlay. Then we import nixpkgs normally, pass our overlay,
  # and use that for everything else in the config.
  #
  # So `nixpkgs-flake` contains nixpkgs, imported as a flake, with no overlays.
  # `nixpkgs` contains nixpkgs, imported normally, with our overlay.
  nixpkgs-flake = imported-flakes.nixpkgs;
  allowed-unfree = import ./unfree.nix;
  nixpkgs = import "${npins.nixpkgs}" {
    overlays = import ../overlays;
    config = {
      allowUnfreePredicate = pkg: elem (nixpkgs-flake.lib.getName pkg) allowed-unfree;
    };
  };
in
imported-flakes
// {
  inherit npins nixpkgs nixpkgs-flake;
}
