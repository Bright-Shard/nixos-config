# Adds a p2pool service for self-hosting p2pool
# For information about p2pool, see https://github.com/SChernykh/p2pool

{
  crux,
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types mkIf;
in
with crux;

{
  options = {
    services.p2pool = {
      enable = mkOption {
        description = "Enable p2pool, a decentralized Monero mining pool. See https://github.com/SChernykh/p2pool for more info.";
        type = types.bool;
        default = false;
      };
      user = mkOption {
        description = "The user to run p2pool as.";
        type = types.str;
        default = "p2pool";
      };
      group = mkOption {
        description = "The group to run p2pool as.";
        type = types.str;
        default = "p2pool";
      };
      dataDir = mkOption {
        description = "The directory to run the p2pool service in, and where its files should be stored.";
        type = types.path;
        default = "/srv/p2pool";
      };
      settings = {
        wallet = mkOption {
          description = "The wallet address mined Monero should be sent to.";
          type = types.str;
        };
        chain = mkOption {
          description = "Which p2pool chain to join. Mini and nano use smaller payouts, but have a lower overall hashrate, meaning you may get paid more often. Therefore smaller chains may be better if you have less hashing power.";
          type = types.enum [
            "default"
            "mini"
            "nano"
          ];
          default = "default";
        };
        stratum = {
          host = mkOption {
            description = "The address Stratum should bind to.";
            type = types.str;
            default = "127.0.0.1";
          };
          port = mkOption {
            description = "The port Stratum should bind to.";
            type = types.port;
            default = 3333;
          };
        };
        p2p = {
          host = mkOption {
            description = "The address the p2p server should bind to.";
            type = types.str;
            default = "127.0.0.1";
          };
          port = mkOption {
            description = "The port the p2p server should bind to.";
            type = types.port;
            default = 37889;
          };
        };
        monero-node = {
          host = mkOption {
            description = "The address of the Monero node to connect to.";
            type = types.str;
            default = "localhost";
          };
          rpc-port = mkOption {
            description = "The port on the Monero node to connect to for RPC.";
            type = types.port;
            default = 18081;
          };
          zmq-port = mkOption {
            description = "The port on the Monero node to connect to for ZMQ.";
            type = types.port;
            default = 18083;
          };
        };
        extraArgs = mkOption {
          description = "Extra CLI arguments to pass to the p2pool executable.";
          type = types.listOf types.str;
          default = [ ];
        };
      };
    };
  };

  config =
    let
      cfg = config.services.p2pool;
    in
    mkIf cfg.enable {
      users = {
        users.${cfg.user} = {
          isSystemUser = true;
          home = cfg.dataDir;
          createHome = true;
          group = cfg.group;
        };
        groups.${cfg.group} = { };
      };

      # https://github.com/SChernykh/p2pool/blob/master/docs/SYSTEMD.MD
      systemd.services.p2pool = rec {
        script = with cfg.settings; ''
          ${pkgs.p2pool}/bin/p2pool \
            --wallet ${wallet} --data-dir ${cfg.dataDir} \
            ${
              if chain == "mini" then
                "--mini"
              else if chain == "nano" then
                "--nano"
              else
                ""
            } \
            --stratum ${stratum.host}:${toString stratum.port} \
            --p2p ${p2p.host}:${toString p2p.port} \
            ${
              with monero-node; "--host ${host} --rpc-port ${toString rpc-port} --zmq-port ${toString zmq-port}"
            } \
            ${concatStringsSep " " extraArgs}
        '';
        wants = [
          "network-online.target"
          "systemd-modules-load.service"
          "monerod.service"
        ];
        after = wants;
        serviceConfig = {
          TimeoutStopSec = 60;
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.dataDir;
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
}
