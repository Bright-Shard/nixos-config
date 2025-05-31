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

  services.tuned = {
    defaultProfiles = false;
    profiles =
      {
        # Standard profile:
        # - Enable CPU boost
        # - Conservative CPU governor
        # - Default GPU performance
        std = {
          main.summary = "Standard profile";
          cpu = {
            boost = 1;
            governor = "conservative";
          };
          video.radeon_powersave = "default";
        };
        # Performance profile:
        # - Enable CPU boost
        # - Performance CPU governor
        # - Maxes the GPU
        perf = {
          main.summary = "Performance profile";
          cpu = {
            boost = 1;
            governor = "performance";
          };
          video.radeon_powersave = "high";
        };
      }
      # Underclocking profiles that:
      # - Restrict system to only use n CPU cores
      # - Disable CPU boost
      # - Powersave CPU governor
      # - Underclock the GPU
      // listToAttrs (
        map
          (
            coresInt:
            let
              cores = toString coresInt;
            in
            {
              name = "uc${cores}";
              value = {
                main.summary = "Underclocked profile that only runs ${cores} CPU cores";
                scheduler.isolated_cores = "${cores}-15";
                cpu = {
                  boost = 0;
                  governor = "powersave";
                };
                video.radeon_powersave = "low";
              };
            }
          )
          [
            4
            8
            12
          ]
      );
  };
}
