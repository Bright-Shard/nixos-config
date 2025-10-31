# Changes the default values for some NixOS settings.
#
# Useful resources:
# https://discourse.nixos.org/t/how-to-change-the-default-nixos-option-in-a-list-of-attrsets-described-as/45561/11

{ lib, ... }:

let
  inherit (lib) mkOption types mkDefault;
in

{
  options = {
    # Set all users to use the default shell by default.
    users.users = mkOption {
      type = lib.types.attrsOf (lib.types.submodule { config.useDefaultShell = mkDefault true; });
    };
    # Bypass workqueues on LUKS-encrypted drives, improving performance by
    # making writes synchronous
    # https://search.nixos.org/options?channel=unstable&show=boot.initrd.luks.devices.%3Cname%3E.bypassWorkqueues&from=0
    boot.initrd.luks.devices = mkOption {
      type = types.attrsOf (types.submodule { config.bypassWorkqueues = mkDefault true; });
    };
  };
}
