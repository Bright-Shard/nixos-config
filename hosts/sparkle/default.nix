{ ... }:

let
  inherit (builtins) listToAttrs map toString;
in
{
  hostOptions = {
    pc = true;
    laptop = true;
    syncthingId = "AGAO3GB-KC7SJML-FNLGI23-NPKGGH4-SLRGJT2-TPYXFCH-JJLCQBQ-I2B3YA4";

    hyprlandSettings = {
      "$mod" = "ALT";
      "$altMod" = "ALT CTRL";
      input.touchpad.scroll_factor = 0.6;
    };
  };

  services.tuned.profiles =
    { }
    # Underclocking profiles that:
    # - Restrict system to only use n CPU cores
    # - Disable CPU boost
    # - Underclock the GPU
    // listToAttrs (
      map
        (coresInt: let cores = toString coresInt; in{
          name = "cores${cores}";
          value = {
            scheduler.isolated_cores = "${cores}-15";
            cpu.boost = 0;
            video.radeon_powersave = "low";
          };
        })
        [
          4
          8
          12
        ]
    );
}
