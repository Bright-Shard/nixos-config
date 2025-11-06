let
  crux = import ./crux.nix;

  inherit (crux)
    replaceStrings
    readFile
    readSubdirs
    listToAttrs
    map
    ;

  NPINS = import ./npins;
  NATIVE-HOST = replaceStrings [ "\n" ] [ "" ] (readFile ./HOSTNAME);
  SPECIAL-ARGS = {
    inherit NPINS crux;
    BUILD-META = { inherit NATIVE-HOST HOSTS SPECIAL-ARGS; };
  };
  MODULES = [
    (
      { ... }:
      {
        nixpkgs.overlays = [
          (import ./nixpkgs)
          (import "${NPINS.nix-minecraft}/overlay.nix")
        ];
      }
    )
    ./options
    ./configuration.nix
    ./hosts/configuration.nix
    "${NPINS.catppuccin}/modules/nixos"
    "${NPINS.home-manager}/nixos"
    "${NPINS.nix-minecraft}/modules/minecraft-servers.nix"
    "${NPINS.nixos-apple-silicon}/apple-silicon-support/modules"
  ];

  HOSTS = listToAttrs (
    map (host: {
      name = host;
      value = import "${NPINS.nixpkgs}/nixos/lib/eval-config.nix" {
        system = builtins.currentSystem;
        specialArgs = SPECIAL-ARGS // {
          BUILD-META = SPECIAL-ARGS.BUILD-META // {
            HOSTNAME = host;
          };
        };
        modules = MODULES ++ [
          ./hosts/${host}
          ./hosts/${host}/hardware-configuration.nix
        ];
      };
    }) (readSubdirs ./hosts)
  );
  BUILT-CONFIG = HOSTS.${NATIVE-HOST};
in

{
  inherit (BUILT-CONFIG) pkgs config options;
  inherit (BUILT-CONFIG.config.system.build) vm vmWithBootloader;
  system = BUILT-CONFIG.config.system.build.toplevel;
}
