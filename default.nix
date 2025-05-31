let
  inherit (builtins)
    fetchGit
    currentSystem
    replaceStrings
    readFile
    readDir
    listToAttrs
    attrNames
    ;
in

{
  configuration ? import <nixpkgs/nixos/lib/from-env.nix> "NIXOS_CONFIG" <nixos-config>,
  system ? currentSystem,
  hostName ? replaceStrings [ "\n" ] [ "" ] (readFile ./HOSTNAME),
  maybeHosts ? null,
}:

let
  # Using this instead of @args so it captures default values
  args = {
    inherit
      configuration
      system
      hostName
      maybeHosts
      ;
  };

  buildHost =
    hostName:
    if hostName == args.hostName then
      eval.config
    else
      (import ./default.nix {
        inherit configuration system hostName;
        maybeHosts = hosts;
      }).config;
  hosts =
    if args.maybeHosts != null then
      args.hosts
    else
      listToAttrs (
        map (hostName: {
          name = hostName;
          value = buildHost hostName;
        }) (attrNames (readDir ./hosts))
      );

  eval = import <nixpkgs/nixos/lib/eval-config.nix> {
    inherit system;
    specialArgs = {
      consts = import ./consts.nix hostName hosts;
    };
    modules = [
      ./hostOptions.nix
      ./modules/tuned.nix

      "${fetchGit "https://github.com/catppuccin/nix"}/modules/nixos"
      "${fetchGit "https://github.com/nix-community/home-manager"}/nixos"

      ./hosts/${hostName}
      ./hosts/${hostName}/hardware-configuration.nix
      configuration
    ];
  };
in

{
  inherit (eval) pkgs config options;

  system = eval.config.system.build.toplevel;

  inherit (eval.config.system.build) vm vmWithBootLoader;
}
