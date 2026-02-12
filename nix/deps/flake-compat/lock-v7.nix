# Fetches dependencies from a version 7 `flake.lock`.

let
  crux = import ../../../crux.nix;
in
with crux;

{
  lock,
  ...
}:

depName:

let
  dep = lock.nodes.${depName}.locked // {
    hash = dep.narHash;
  };
  ty = dep.type;
  fetcher =
    if ty == "file" then
      PKGS.fetchurl
    else if ty == "github" then
      PKGS.fetchFromGitHub
    else if ty == "git" then
      PKGS.fetchgit
    else if ty == "tarball" then
      PKGS.fetchzip
    else
      throw "TODO: `flake.lock` v7 dependency type ${ty}";
  args = removeAttrs dep [
    "lastModified"
    "narHash"
    "type"
  ];
in
fetcher args
