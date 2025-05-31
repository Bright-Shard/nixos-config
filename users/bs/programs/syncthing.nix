{ consts, ... }:

with builtins;
let
  extraHosts = {
    reclaimed = {
      addresses = [ "tcp://reclaimed.bs" ];
      id = "5WL5JWE-2QQHT4G-RFFE35O-R5WN6C3-OGKIDEN-OBNSQZR-AL57K7Q-2JZOVQ3";
    };
  };
  hasSyncthingId =
    hostName:
    if (consts.hosts.${hostName}.hostOptions.syncthingId != null) then
      true
    else
      warn "Host '${hostName}' doesn't have a Syncthing ID" false;
in
{
  services.syncthing = rec {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices =
        extraHosts
        // (listToAttrs (
          map (hostName: {
            name = hostName;
            value = {
              addresses = [ "tcp://${hostName}.bs" ];
              id = consts.hosts.${hostName}.hostOptions.syncthingId;
            };
          }) (filter hasSyncthingId (attrNames consts.hosts))
        ));
      folders =
        let
          folder = id: {
            enable = true;
            inherit id;
            devices = attrNames settings.devices;
          };
        in
        {
          "~/dev" = folder "jko99-qppnq";
          "~/hacking" = folder "zceck-haczp";
          "~/Documents/texts" = folder "ybnvf-fumyf";
          "~/Photos" = folder "pixel_7_yxha-photos";
          "~/afia" = folder "symzn-kjmpp";
          "~/.local/share/osu" = folder "osu-727";
          "~/.zen" = folder "zen-sync";
        };
    };
  };
}
