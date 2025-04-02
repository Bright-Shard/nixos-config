{
  lib,
  pkgs,
  config,
  ...
}@inputs:

with builtins;
let
  HOSTNAME = replaceStrings [ "\n" ] [ "" ] (readFile ./HOSTNAME);
  home-manager = fetchGit "https://github.com/nix-community/home-manager";
  CONSTS = import ./consts.nix inputs;
in
{
  options = {
    hostOptions = import ./hostOptions.nix lib;
  };

  imports = [
    ./hosts/${HOSTNAME}/hardware-configuration.nix
    ./hosts/${HOSTNAME}
    "${home-manager}/nixos"
    "${fetchTarball "https://github.com/catppuccin/nix/archive/main.tar.gz"}/modules/nixos"
  ];

  config =
    let
      inherit (config) hostOptions;
      inherit (lib) mkIf mkMerge;
    in
    mkMerge [
      {
        catppuccin.enable = true;

        boot.loader = {
          grub.device = "nodev";
          grub.efiSupport = true;
          efi.canTouchEfiVariables = true;
        };

        networking = {
          hostName = HOSTNAME;
          networkmanager.enable = true;
        };

        time.timeZone = "America/New_York";
        i18n.defaultLocale = "en_US.UTF-8";

        services = {
          pipewire = {
            enable = true;
            pulse.enable = true;
            wireplumber.enable = true;
          };
          openssh = {
            enable = true;
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "no";
            };
          };
        };

        users.users = {
          bs = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            shell = pkgs.zsh;
            openssh.authorizedKeys.keys = [ CONSTS.SSH_KEY ];
          };
        };
        home-manager.extraSpecialArgs = {
          inherit CONSTS;
          inherit hostOptions;
        };
        home-manager.users.bs = import ./users/bs;

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

        environment.systemPackages = with pkgs; [
          git
          vim
          w3m
        ];
        environment.etc = {
          # Allows the 1Password browser extension to communicate with the
          # 1Password app in Zen Browser
          zen-1password-patch = {
            target = "1password/custom_allowed_browsers";
            text = ".zen-wrapped\n";
            mode = "0755";
          };
        };
        fonts.packages = with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-emoji
          nerd-fonts.shure-tech-mono
        ];

        programs = {
          zsh.enable = true;
        };
        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "1password"
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
          steam.enable = true;
          _1password-gui.enable = true;
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
