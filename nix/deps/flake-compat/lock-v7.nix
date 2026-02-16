# Fetches dependencies from a version 7 `flake.lock`.

{
  lock,
  pkgs,
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
      pkgs.fetchurl
    else if ty == "github" then
      pkgs.fetchFromGitHub
    else if ty == "git" then
      pkgs.fetchgit
    else if ty == "tarball" then
      pkgs.fetchzip
    else
      throw "TODO: `flake.lock` v7 dependency type ${ty}";
  args = removeAttrs dep [
    "lastModified"
    "narHash"
    "type"
  ];
in
fetcher args
