{
  lib,
  crux,
  ...
}:

let
  inherit (lib) mkOption types;
in
with crux;

{
  options = {
    # I put all my custom options in the "bs" namespace
    bs = {
      gui = mkOption {
        description = "Installs GUI programs (e.g. the 1Password GUI) when enabled.";
        type = types.bool;
      };
      ros = mkOption {
        description = "Installs ROS dev tooling.";
        type = types.bool;
        default = false;
      };
      syncthingId = mkOption {
        description = "A unique ID for this host in Syncthing.";
        type = types.str;
      };
      mullvad = mkOption {
        description = "Enables Mullvad VPN.";
        type = types.bool;
      };
      mod = mkOption {
        description = "Default modifier key for Niri keybinds.";
        type = types.str;
      };
      altMod = mkOption {
        description = "Secondary modifier key for Niri keybinds.";
        type = types.str;
      };
      firewall = mkOption {
        description = "Extra firewall configuration.";
        type = types.submodule (
          { ... }:
          {
            options = {
              logViolations = mkOption {
                description = "Log when the firewall rejects a connection.";
                type = types.bool;
                default = true;
              };
              globalWhitelistRules = mkOption {
                description = "Firewall rules to add to the global whitelist chain.";
                type = types.str;
                default = "";
              };
              openGlobalPorts = {
                tcp = mkOption {
                  description = "TCP ports to open to every interface.";
                  type = types.listOf types.ints.u16;
                  default = [ ];
                };
                udp = mkOption {
                  description = "UDP ports to open to every interface.";
                  type = types.listOf types.ints.u16;
                  default = [ ];
                };
              };
              openLanPorts = {
                tcp = mkOption {
                  description = "TCP ports to open to LAN.";
                  type = types.listOf types.ints.u16;
                  default = [ ];
                };
                udp = mkOption {
                  description = "UDP ports to open to LAN.";
                  type = types.listOf types.ints.u16;
                  default = [ ];
                };
              };
              openInterfacePorts = mkOption {
                description = "Ports to open for specific interfaces.";
                type = types.attrsOf (
                  types.submodule (
                    { ... }:
                    {
                      options = {
                        tcp = mkOption {
                          description = "TCP ports to open on this interface.";
                          type = types.listOf types.ints.u16;
                          default = [ ];
                        };
                        udp = mkOption {
                          description = "UDP ports to open on this interface.";
                          type = types.listOf types.ints.u16;
                          default = [ ];
                        };
                      };
                    }
                  )
                );
                default = { };
              };
            };
          }
        );
        default = { };
      };
      apple-silicon = mkOption {
        description = "If this host runs on Apple Silicon hardware.";
        type = types.bool;
        default = false;
      };
      state-version = mkOption {
        description = "The state version for Home Manager and NixOS on this host.";
        type = types.str;
      };
    };
  };

  config = { };
}
