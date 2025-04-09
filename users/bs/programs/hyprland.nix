{
  pkgs,
  lib,
  bsUtils,
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
        brightnessctl

        # Background Services
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        dunst
        hyprpolkitagent

        # Extremely crucial package
        # I'd die without it
        # Seriously, where would the world be
        pipes
      ];

      wayland.windowManager.hyprland = with builtins; {
        enable = true;
        systemd.enable = true;
        settings = {
          exec-once = [
            "eww daemon"
            "eww update isLaptop=${toString hostOptions.laptop}"
          ];
          general = {
            gaps_out = 12;
          };
          decoration = {
            rounding = 10;
            inactive_opacity = ".8";
          };
          input = {
            accel_profile = "flat";
            scroll_method = "on_button_down";
            scroll_button = 274;
            touchpad.clickfinger_behavior = true;
            numlock_by_default = true;
          };
          gestures = {
            workspace_swipe = true;
            workspace_swipe_use_r = true;
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
              "$mod, O, exec, brightnessctl s 10%+"
              "$mod, I, exec, brightnessctl s 10%-"
              "$mod, B, exec, if [ \"$(eww active-windows | grep bar)\" = \"bar: bar\" ]; then eww close bar; else eww open bar; fi"
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
          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];
        };
      };

      programs = {
        hyprlock = {
          enable = true;
          settings = {
            general.hide_cursor = true;
          };
        };
        # Enable waybar so catppuccin adds the css theme file,
        # which we then import into eww
        waybar = {
          enable = true;
        };
        eww = {
          enable = true;
          configDir = ./eww;
        };
      };

      services = {
        dunst.enable = true;
        gnome-keyring.enable = true;
      };
    }

    { wayland.windowManager.hyprland.settings = hostOptions.hyprlandSettings; }
  ];
}
