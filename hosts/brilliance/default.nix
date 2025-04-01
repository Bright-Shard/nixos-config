{ ... }:
{
  hostOptions = {
    pc = true;

    hyprlandSettings = {
      "$mod" = "SHIFT CTRL ALT SUPER";
      "$altMod" = "SHIFT CTRL ALT";
      monitor = [
        # name, resolution, position, scale
        "DP-3, 2560x1440@180.00Hz, auto, auto"
        "HDMI-A-1, preferred, auto, auto, transform, 1"
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
