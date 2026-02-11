# Adds the overlays from `/nix/overlays` to nixpkgs through the NixOS nixpkgs
# config

{
  nixpkgs.overlays = import ../overlays;
}
