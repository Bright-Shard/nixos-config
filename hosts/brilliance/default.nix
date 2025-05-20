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
      services.syncthing.settings.folders."~/afia".path = "/external/500gb/afia";
    };
  };

  fileSystems =
    let
      drive = size: letter: {
        "/external/${size}" = {
          device = "/dev/${letter}";
          fsType = "ext4";
        };
      };
    in
    drive "1tb" "sdb1" // drive "500gb" "sda1";
}
