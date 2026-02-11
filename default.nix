let
  crux = import ./crux.nix;

  cfg = crux.HOSTS.${crux.NATIVE-HOSTNAME};
in

{
  inherit (cfg) pkgs config options;
  inherit (cfg.config.system.build) vm vmWithBootloader;
  system = cfg.config.system.build.toplevel;
}
