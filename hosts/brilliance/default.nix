{ ... }:
let
  mainMonitor = "DP-2";
  sideMonitor = "HDMI-A-1";
in
{
  hostOptions = {
    pc = true;
    laptop = false;
    syncthingId = "CMDCB6R-LD2ONBZ-DLOICW3-34NG2ET-3RLCQCV-7NMJC72-TUSXOSH-3A3Q3AU";

    hyprlandSettings = with builtins; {
      "$mod" = "SHIFT CTRL ALT SUPER";
      "$altMod" = "SHIFT CTRL ALT";
      monitor = [
        # name, resolution, position, scale
        "${mainMonitor}, 2560x1440@180.00Hz, auto, auto"
        "${sideMonitor}, preferred, auto, auto, transform, 1"
      ];
      workspace = concatLists [
        (genList (val: "${toString (val + 1)},monitor:${mainMonitor}") 5)
        (map (val: "${toString val},monitor:${sideMonitor}") ([ 0 ] ++ genList (val: val + 6) 4))
      ];
    };

    home-manager = { ... }:
    {
      services.syncthing.settings.folders."~/afia".path = "/external/1tb/afia";
    };
  };

  fileSystems =
    let
      drive = size: uuid: {
        "/external/${size}" = {
          device = "/dev/disk/by-partuuid/${uuid}";
          fsType = "ext4";
        };
      };
    in
    drive "1tb" "fa4c4b84-b29c-4464-b45d-ab4140da1560" // drive "500gb" "294976ec-c6a8-414f-86e8-a446e05cfeb0";
}
