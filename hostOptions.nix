{ options, types, ... }:

let
  inherit (options) mkOption;
in
{
  amdGpu = mkOption {
    description = "Whether or not to install AMD GPU drivers.";
    type = types.bool;
    default = true;
  };
  intranet = mkOption {
    description = "Whether or not to connect this host to the intranet.";
    type = types.bool;
    default = true;
  };
  pc = mkOption {
    description = "Whether this host is a PC or a server. When this option is enabled, additional PC apps (like Steam) will be installed.";
    type = types.bool;
  };
  syncthingId = mkOption {
    description = "This host's Syncthing ID.";
    type = types.string;
  };
  hyprlandSettings = mkOption {
    description = "Additional Hyprland settings for this host.";
    type = types.attrs;
    default = { };
  };
}
