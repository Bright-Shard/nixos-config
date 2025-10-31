{ NPINS, pkgs, ... }:

{
  imports = [ "${NPINS.nixware}/framework/16-inch/7040-amd" ];

  config = {
    bs = {
      gui = true;
      syncthingId = "IC2AOF2-HHOYJ3S-2SGCGET-7JETQ7T-UP2IEWR-ZYPEDHI-6EU4PHE-5UU33AC";
      mullvad = true;
      mod = "Alt+Super";
      altMod = "Ctrl+Alt+Super";
    };

    home-manager.users.bs =
      { ... }:
      {
        # Custom battery widget for the laptop
        programs.waybar.settings.bar = {
          modules-right = [ "custom/battery" ];
          "custom/battery" = {
            exec = pkgs.writeShellScript "bat" ''
              BAT=/sys/class/power_supply/BAT1
              CAP=$(cat $BAT/capacity)

              if [[ $(cat $BAT/status) = "Charging" ]]; then
              	icon="󰂄"
              else
              	case $CAP in
              		100)
              			icon="󰁹"
              		;;
              		9?)
              			icon="󰂂"
              		;;
              		8?)
              			icon="󰂁"
              		;;
              		7?)
              			icon="󰂀"
              		;;
              		6?)
              			icon="󰁿"
              		;;
              		5?)
              			icon="󰁾"
              		;;
              		4?)
              			icon="󰁽"
              		;;
              		3?)
              			icon="󰁼"
              		;;
              		2?)
              			icon="󰁻"
              		;;
              		1? | 0?)
              			icon="󰁺"
              		;;
              	esac
              fi

              echo "$icon $CAP%"
            '';
            interval = 1;
            format = "{}";
          };
        };
      };

    services = {
      # https://wiki.nixos.org/wiki/Hardware/Framework/Laptop_16#Prevent_wake_up_in_backpack
      udev.extraRules = ''
        SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="32ac", ATTR{power/wakeup}="disabled", ATTR{driver/1-1.1.1.4/power/wakeup}="disabled"
      '';
      # I use TuneD :p
      power-profiles-daemon.enable = false;
      tlp.enable = false;
    };

    networking.networkmanager.wifi.backend = "iwd";

    # This option defines the first version of NixOS you have installed on this particular machine,
    # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
    #
    # Most users should NEVER change this value after the initial install, for any reason,
    # even if you've upgraded your system to a new NixOS release.
    #
    # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
    # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
    # to actually do that.
    #
    # This value being lower than the current NixOS release does NOT mean your system is
    # out of date, out of support, or vulnerable.
    #
    # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
    # and migrated your data accordingly.
    #
    # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    system.stateVersion = "24.11"; # Did you read the comment?
  };
}
