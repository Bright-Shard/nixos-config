{
  lib,
  pkgs,
  config,
  consts,
  ...
}@inputs:

with builtins;
let
  inherit (config) hostOptions;
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    ;
in
{
  options = {
    # Bypass workqueues for all LUKS devices by default
    # This is a performance optimisation: https://search.nixos.org/options?channel=unstable&show=boot.initrd.luks.devices.%3Cname%3E.bypassWorkqueues&from=0
    # See https://discourse.nixos.org/t/how-to-change-the-default-nixos-option-in-a-list-of-attrsets-described-as/45561/11 for source for this code
    boot.initrd.luks.devices = mkOption {
      type = types.attrsOf (types.submodule { config.bypassWorkqueues = true; });
    };
  };
  config = mkMerge [
    {
      catppuccin.enable = true;

      boot.loader = {
        grub.device = "nodev";
        grub.efiSupport = true;
        efi.canTouchEfiVariables = true;
      };

      networking = {
        hostName = consts.hostName;
        networkmanager.enable = true;
        firewall.enable = false;
      };

      time.timeZone = "America/New_York";
      i18n.defaultLocale = "en_US.UTF-8";

      users = {
        groups = {
          nixSync = { };
          plugdev = { };
        };
        users = {
          bs = {
            isNormalUser = true;
            extraGroups = [
              "wheel"
              "plugdev"
              "wireshark"
            ];
            shell = pkgs.zsh;
            openssh.authorizedKeys.keys = [ consts.sshKey ];
          };
          # Dedicated user for syncing my nixOS config - see the syncthing cfg
          # below
          nixSync = {
            isNormalUser = true;
            home = "/var/nixSync";
            group = "nixSync";
            extraGroups = [ "users" ];
          };
        };
      };

      services = {
        mullvad-vpn.enable = true;
        tuned.enable = true;
        envfs.enable = true;
        udev.extraRules = ''
          # Adafruit: https://learn.adafruit.com/circuitpython-libraries-on-any-computer-with-mcp2221/linux
          SUBSYSTEMS=="usb", ACTION=="add", ATTRS{idVendor}=="04d8", ATTRS{idProduct}=="00dd", GROUP="plugdev", MODE="0666"
        '';
        pipewire = {
          enable = true;
          pulse.enable = true;
          wireplumber.enable = true;
          alsa.enable = true;
          jack.enable = true;
        };
        openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            PermitRootLogin = "no";
          };
        };
        avahi = {
          enable = true;
          nssmdns4 = true;
          nssmdns6 = true;
        };
        # Sync nixOS config to my server automatically.
        syncthing = {
          enable = true;
          group = "nixSync";
          user = "nixSync";
          dataDir = "/var/nixSync";
          configDir = "/var/nixSync/config";
          guiAddress = "localhost:8385";
          openDefaultPorts = false;
          settings = {
            options = {
              listenAddresses = [
                "quic://:22001"
                "tcp://:22001"
              ];
              localAnnounceEnabled = false;
            };
            folders = {
              "/etc/nixos" = {
                label = "NixOS Config";
                id = "wanwan";
                devices = [ "reclaimed" ];
              };
            };
            devices = {
              reclaimed = {
                addresses = [ "tcp://reclaimed.bs" ];
                id = "5WL5JWE-2QQHT4G-RFFE35O-R5WN6C3-OGKIDEN-OBNSQZR-AL57K7Q-2JZOVQ3";
                autoAcceptFolders = false;
              };
            };
          };
        };
      };

      home-manager = {
        extraSpecialArgs = { inherit consts; };
        users.bs = import ./users/bs;
      };

      hardware = {
        graphics = (
          mkIf hostOptions.amdGpu {
            enable = true;
            extraPackages = [
              pkgs.amdvlk
              pkgs.rocmPackages.clr.icd
            ];
            extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
          }
        );
        gpgSmartcards.enable = true;
      };

      environment = {
        systemPackages = with pkgs; [
          git
          vim
          w3m
          busybox
          nixfmt-rfc-style
        ];
        etc = {
          # Allows the 1Password browser extension to communicate with the
          # 1Password app in Zen Browser
          #
          # TODO: This is currently broken. It seems the zen binary also needs
          # to be owned by the same user `1password` is running as. However,
          # it's currently installed by NixOS as root.
          "1password/custom_allowed_browsers" = {
            text = ".zen-wrapped";
            mode = "0755";
          };
        };
        shellAliases = {
          cfgupdate = "sudo nixos-rebuild switch --file /etc/nixos";
          sysupdate = ''
            sudo nix-channel --update
            cfgupdate
          '';
          # Clears screen and scrollback, instead of just screen:
          # https://github.com/kovidgoyal/kitty/issues/268#issuecomment-419342337
          clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
        };
      };

      # Put /etc/nixos under nixSync so nixSync can sync it w/
      # Syncthing, but give bs access to .git and users/bs so
      # I can make commits and change user-level settings w/o
      # sudo.
      systemd.tmpfiles.settings = {
        "10-nixperms" = {
          "/etc/nixos".Z = {
            user = "nixSync";
            group = "nixSync";
          };
          "/etc/nixos/.git".Z = {
            user = "bs";
            group = "nixSync";
            mode = "0770";
          };
          "/etc/nixos/users/bs".Z = {
            user = "bs";
            group = "nixSync";
            mode = "0770";
          };
        };
      };

      fonts.packages = with pkgs; [
        nerd-fonts.shure-tech-mono
        noto-fonts
        noto-fonts-lgc-plus
        noto-fonts-cjk-sans
        noto-fonts-monochrome-emoji
        noto-fonts-emoji-blob-bin
      ];

      programs = {
        zsh = {
          enable = true;
          histFile = "/dev/null";
        };
        wireshark.enable = true;
      };
      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "1password"
          "1password-cli"
          "steam"
          "steam-unwrapped"
        ];

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
    }

    (mkIf hostOptions.pc {
      services.printing.enable = true;
      programs = {
        steam = {
          enable = true;
          extraCompatPackages = with pkgs; [ proton-ge-bin ];
        };
        _1password-gui.enable = true;
        _1password.enable = true;
        dconf.enable = true;
      };
    })

    (mkIf hostOptions.intranet {
      services = {
        resolved.enable = true;
        tailscale.enable = true;
      };
    })
  ];
}
