{ ... }:
{
  hostOptions = {
    pc = true;

    hyprlandSettings = with builtins; {
      "$mod" = "SHIFT CTRL ALT SUPER";
      "$altMod" = "SHIFT CTRL ALT";
      monitor = [
        # name, resolution, position, scale
        "DP-3, 2560x1440@180.00Hz, auto, auto"
        "HDMI-A-1, preferred, auto, auto, transform, 1"
      ];
      workspace = concatLists [
        (genList (val: "${toString (val + 1)},monitor:DP-3") 5)
        (map (val: "${toString val},monitor:HDMI-A-1") ([ 0 ] ++ genList (val: val + 6) 4))
      ];
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
