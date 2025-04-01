{
  pkgs,
  lib,
  ...
}@inputs:

let
  hostOptions = inputs.osConfig.hostOptions;
in
{
  config = lib.mkMerge [
    {
      home.packages = with pkgs; [
        # Hyprland & needed apps
        hyprland
        hyprcursor
        kitty
        pwvucontrol

        # Utilities
        hyprlock
        bemenu
        wl-clipboard
        grim
        slurp

        # Background Services
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        dunst
        hyprpolkitagent
      ];

      wayland.windowManager.hyprland = with builtins; {
        enable = true;
        settings = {
          decoration = {
            rounding = 10;
            inactive_opacity = ".8";
          };
          input = {
            accel_profile = "flat";
            scroll_method = "on_button_down";
            scroll_button = 274;
          };
          bind = concatLists [
            [
              "$mod, T, exec, kitty"
              "$mod, SPACE, exec, bemenu-run --accept-single"
              "$altMod, L, exec, hyprlock"
              "$mod, Q, killactive"
              "$mod, Z, exit"
              "$mod, F, fullscreen"
              "$mod, mouse_down, workspace, e+1"
              "$mod, mouse_up, workspace, e-1"
              "CTRL SHIFT, X, exec, grim -g \"$(slurp)\" /dev/stdout | wl-copy -t 'image/png'"
            ]
            (
              let
                map = val: [
                  "$mod, ${toString val}, workspace, ${toString val}"
                  "$altMod, ${toString val}, movetoworkspacesilent, ${toString val}"
                ];
              in
              concatLists (genList map 10)
            )
          ];
          workspace = concatLists [
            (genList (val: "${toString (val + 1)},monitor:DP-3") 5)
            (map (val: "${toString val},monitor:HDMI-A-1") ([ 0 ] ++ genList (val: val + 6) 4))
          ];
          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];
        };
      };
    }

    { wayland.windowManager.hyprland.settings = hostOptions.hyprlandSettings; }
  ];
}
