# Nix configurations that only apply to hosts (e.g. not containers)
{
  crux,
  pkgs,
  lib,
  config,
  BUILD-META,
  ...
}:

with crux;
let
  inherit (lib) mkMerge mkIf;
in

mkMerge [
  # Boot & Kernel
  {
    boot = {
      loader = {
        grub = {
          device = "nodev";
          efiSupport = true;
        };
        efi.canTouchEfiVariables = true;
      };
    };
    # Needed with Linux-hardened for normal users to be able to create user
    # namespaces
    # Disabled by default in hardened Linux as user namespaces have caused
    # multiple kernel privesc exploits in the past when the kernel failed to
    # properly account for namespaces
    security.unprivilegedUsernsClone = true;
  }
  (mkIf (!config.bs.apple-silicon) {
    # boot.kernelPackages = pkgs.callPackage ../nixpkgs/kernel.nix { };
    # TODO: Current Embark games (Arc Raiders & The Finals) break with
    # linux-hardened. IDK why. just using the normal kernel for now...
    boot.kernelPackages = pkgs.linuxPackages_latest;
  })

  # Networking
  {
    bs.firewall = {
      openLanPorts = {
        tcp = [
          22 # SSH
          22000 # Syncthing TCP
        ];
        udp = [
          22000 # Syncthing QUIC
          21027 # Syncthing discovery
          #5353 # mDNS
          41641 # TailScale
          67 # DHCP
          68 # DHCP
          5355 # LLMNR
        ];
      };
      openInterfacePorts.tailscale0 = {
        tcp = [
          22 # SSH
          22000 # Syncthing TCP
        ];
        udp = [
          22000 # Syncthing QUIC
        ];
      };
    };
    networking = {
      networkmanager.enable = true;
      nftables = {
        enable = true;
        tables = mkMerge [
          {
            portFilter = {
              family = "inet";
              content =
                let
                  inherit (config.bs) firewall;

                  portsList =
                    prefix: portsList:
                    if portsList != [ ] then
                      "${prefix} dport { ${concatStringsSep ", " (map (port: toString port) portsList)} } accept;"
                    else
                      "";
                in
                ''
                  chain input {
                    type filter hook input priority 0; policy drop;
                    iifname "lo" accept;
                    ct state vmap { invalid : drop, established : accept, related : accept, new : jump whitelist, untracked : jump whitelist };
                    ${if firewall.logViolations then ''log prefix "(firewall) refused packet: " level info;'' else ""}
                  }

                  chain whitelist {
                    ip protocol icmp accept;
                    ${portsList "tcp" firewall.openGlobalPorts.tcp}
                    ${portsList "udp" firewall.openGlobalPorts.udp}

                    ip saddr { ${concatStringsSep ", " RESERVED-IPS.IPv4.LAN} } jump lanWhitelist;
                    ip6 saddr { ${RESERVED-IPS.IPv6.UNIQUE-LOCAL-ADDRESS} } jump lanWhitelist;

                    ${concatStringsSep "\n" (
                      map (interface: ''
                        ${portsList "iifname \"${interface}\" tcp" firewall.openInterfacePorts.${interface}.tcp}
                        ${portsList "iifname \"${interface}\" udp" firewall.openInterfacePorts.${interface}.udp}
                      '') (attrNames firewall.openInterfacePorts)
                    )}

                    ${firewall.globalWhitelistRules}
                  }

                  chain lanWhitelist {
                    ${portsList "tcp" firewall.openLanPorts.tcp}
                    ${portsList "udp" firewall.openLanPorts.udp}
                  }

                  # Firewall rules for TailScale exit nodes
                  #
                  # Traffic coming from the Tailnet destined for the wider
                  # internet gets marked with CT label 1 and masqueraded.
                  # Masquerading makes the server see the packet as coming
                  # from the TailScale exit node (instead of retaining the
                  # tailnet member's IP address), so the server sends response
                  # packets back to the exit node as expected.
                  # Then, whenever the exit node receives packets marked with
                  # CT label 1, it marks the packet to be excluded from Mullvad.
                  # Technically the second half is only necessary for hosts
                  # connected to Mullvad VPN, but for now it's implemented
                  # globally.
                  #
                  # Note that exit nodes also need to have IP forwarding enabled
                  # for this to work; see Hibana's config for an example.
                  chain tailnetExitNodeOut {
                    type nat hook postrouting priority 99; policy accept;
                    # Ignore Tailnet->Tailnet traffic
                    ip daddr ${RESERVED-IPS.IPv4.CARRIER-GRADE-NAT} accept;
                    ip6 daddr fd7a:115c:a1e0::/48 accept;
                    # Ignore TailScale's internal IP
                    # https://tailscale.com/kb/1381/what-is-quad100
                    ip saddr 100.100.100.100 accept;
                    ip6 saddr fd7a:115c:a1e0::53 accept;

                    iifname "tailscale0" oifname "wg0-mullvad" ip saddr ${RESERVED-IPS.IPv4.CARRIER-GRADE-NAT} meta nftrace set 1 ct label set 1 masquerade;
                    iifname "tailscale0" oifname "wg0-mullvad" ip6 saddr fd7a:115c:a1e0::/48 meta nftrace set 1 ct label set 1 masquerade;
                  }
                  chain tailnetExitNodeIn {
                    type filter hook prerouting priority -100; policy accept;

                    ct label 1 meta mark set 0x6d6f6c65;
                  }

                  # chain debug {
                  #   type filter hook prerouting priority -300; policy accept;
                  #   meta nftrace set 1;
                  # }
                '';
            };
          }

          (mkIf config.bs.mullvad {
            # Exclude tzupdate and Tailscale from Mullvad.
            #
            # tzupdate sets your timezone based on IP address. So if it goes
            # through Mullvad my timezone gets set to the timezone of the
            # Mullvad server.
            # Tailscale loses a lot of speed if it has to hop through Mullvad
            # instead of working p2p.
            #
            # tzupdate is marked by the group ID the service runs as - 727 -
            # while Tailscale is marked by destination IP addresses being
            # within the tailnet.
            #
            # https://theorangeone.net/posts/tailscale-mullvad/
            # https://mullvad.net/en/help/split-tunneling-with-linux-advanced
            mullvadBypasses = {
              family = "inet";
              content = ''
                chain bypassMullvadOut {
                  type route hook output priority -100; policy accept;
                  # Always bypass Mullvad firewall
                  ct mark set 0x00000f41;
                  # Bypass Mullvad tunnel for Tailnet + tzupdate
                  ip daddr 100.64.0.0/10 meta mark set 0x6d6f6c65;
                  meta skgid 727 meta mark set 0x6d6f6c65;
                  # Bypass Mullvad tunnel for DNS queries
                  ip daddr 194.242.2.2 meta mark set 0x6d6f6c65;
                }
                chain bypassMullvadFirewallIn {
                  type filter hook input priority -100; policy accept;
                  # Always bypass Mullvad firewall
                  ct mark set 0x00000f41;
                }
                # Yes this needs to be in a nat chain and not a filter chain
                # No I'm not sure why
                chain bypassMullvadTunnelIn {
                  type nat hook input priority -100; policy accept;
                  # Bypass Mullvad tunnel for Tailnet + tzupdate
                  ip saddr 100.64.0.0/10 meta mark set 0x6d6f6c65;
                  meta skgid 727 meta mark set 0x6d6f6c65;
                }
                # Mullvad masquerades all traffic that bypasses their firewall
                # For some reason
                # Anyways we actually do want that for the tailnet but not other
                # traffic
                chain bypassMullvadMasquerade {
                  type nat hook postrouting priority 99; policy accept;
                  ip daddr 100.64.0.0/10 accept;
                  ct mark set 0;
                }
              '';
            };
          })
        ];
      };
      firewall.enable = false;
    };
    services = mkMerge [
      {
        avahi = {
          enable = false;
          nssmdns4 = true;
          nssmdns6 = true;
        };
        resolved.enable = true;
        tailscale = {
          enable = true;
          extraDaemonFlags = [ "-no-logs-no-support" ];
        };
        openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
          };
        };
      }

      (mkIf config.bs.mullvad { mullvad-vpn.enable = true; })

      (mkIf config.bs.gui { printing.enable = true; })
    ];
    # Force TailScale MTU to be a specific size
    # The default size (1280 as of Nov 2025) causes lots of packet loss for me
    systemd.services.tailscaled.environment = {
      TS_DEBUG_MTU = "1024";
    };
  }

  # Hardware
  {
    # Grants extra permissions for USB devices; similar to "plugdev"
    # on other systems
    users.groups.usb = { };
    services = {
      udev = {
        packages = with pkgs; [ logitech-udev-rules ];
        extraRules = ''
          # ZSA Oryx for my Moonlander
          KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="usb"
          KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="usb"
          SUBSYSTEM=="usb", ATTR{idVendor}=="3297", GROUP="usb"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE:="0666", SYMLINK+="stm32_dfu"
        '';
      };
      # Performance profiles
      tuned = {
        enable = true;
        profiles = {
          # Standard profile:
          # - Enable CPU boost
          # - Conservative CPU governor
          # - Default GPU performance
          std = {
            main.summary = "Standard profile";
            scheduler.isolated_cores = "";
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
            main = {
              summary = "Performance profile";
              include = "latency-performance";
            };
            scheduler.isolated_cores = "";
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
                  main = {
                    summary = "Underclocked profile that only runs ${cores} CPU cores";
                    include = "powersave";
                  };
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
      # Firmware updating tool
      fwupd.enable = true;
      # Audio
      pipewire = {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
      };
    };
    hardware.asahi.enable = config.bs.apple-silicon;
    # Recommended to let Pipewire use realtime scheduling
    # https://wiki.nixos.org/wiki/PipeWire
    security.rtkit.enable = true;
    zramSwap = {
      enable = true;
      memoryPercent = 30;
    };
  }
  (mkIf config.bs.gui {
    hardware = {
      opentabletdriver.enable = true;
      graphics.enable = true;
      graphics.enable32Bit = true;
      amdgpu = {
        # overdrive.enable = true;
        opencl.enable = true;
      };
    };
  })

  # Time
  {
    # tzupdate automatically updates your timezone based on your
    # location.
    # It seems to use your IP to determine your location, because
    # connecting to Mullvad makes it set the wrong timezone. To work
    # around this we make it run under a specific group that has
    # special firewall rules to make it route outside of Mullvad. See
    # the networking section for those rules.
    services.tzupdate.enable = false;
    users.groups.tzupdate.gid = 727;
    systemd.services.tzupdate.serviceConfig.Group = "tzupdate";
  }

  # Users
  {
    users = {
      users = {
        bs = {
          extraGroups = [ "usb" ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpccNDjO3RI6swBEZCT+ZyGDN10jkmm3re/1PcJqgkL"
          ];
        };
        root.autoSubUidGidRange = true;
      };
    };
  }

  # Syncthing
  {
    services.syncthing = rec {
      enable = true;
      user = "bs";
      group = "users";
      overrideDevices = true;
      overrideFolders = true;
      dataDir = "/home/bs";
      settings = {
        options.urAccepted = 3;

        devices = listToAttrs (
          map (host: {
            name = host;
            value = {
              addresses = [
                "quic://${host}.bs"
                "tcp://${host}.bs"
              ];
              id = BUILD-META.HOSTS.${host}.config.bs.syncthingId;
            };
          }) (filter (host: host != BUILD-META.HOSTNAME) (attrNames BUILD-META.HOSTS))
        );

        folders =
          let
            folder = id: {
              enable = true;
              inherit id;
              devices = attrNames settings.devices;
            };
          in
          {
            "/home/bs/dev" = folder "jko99-qppnq";
            "/home/bs/hacking" = folder "zceck-haczp";
            "/home/bs/documents" = folder "ybnvf-fumyf";
            "/home/bs/media" = folder "pixel_7_yxha-photos";
            "/home/bs/afia" = folder "symzn-kjmpp";
            "/home/bs/.local/share/osu" = folder "osu-727";
            "/etc/nixos" = folder "wanwan";
          };
      };
    };
    systemd.tmpfiles.settings = {
      "10-nixos-config" = {
        "/etc/nixos".Z = {
          user = "bs";
          group = "users";
        };
      };
      "10-srv" = {
        "/srv".d = {
          mode = "777";
        };
      };
    };
  }

  # Containers
  {
    # bs.containers = mapAttrs (name: val: import ../containers/${name} inputs) (readDir ../containers);
  }

  # Shell
  {
    environment = {
      systemPackages = with pkgs; [ npins ];
      shellAliases = {
        # pwn = "sudo nixos-container root-login pwnshell";
        # System update aliases
        cfgupdate = "nixos-rebuild switch --file /etc/nixos --sudo";
        sysupdate = "cp -r /etc/nixos/npins /etc/nixos/npins.bak; ${pkgs.npins}/bin/npins -d /etc/nixos/npins upgrade; ${pkgs.npins}/bin/npins -d /etc/nixos/npins update; cfgupdate";
      };
    };
  }

  # yuh we gaymin
  (mkIf config.bs.gui {
    environment = {
      systemPackages = with pkgs; [ gamescope ];
      etc = {
        "1password/custom_allowed_browsers" = {
          text = ''
            .zen-wrapped
          '';
          mode = "0755";
        };
      };
    };
    programs = {
      appimage = {
        enable = true;
        binfmt = true;
      };
      steam = {
        enable = true;
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
      };
      _1password-gui.enable = true;
      _1password.enable = true;
      dconf.enable = true;
    };
    xdg.portal = {
      enable = true;
      config = { };
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };
    services.flatpak = {
      enable = true;
      packages = [ ];
    };
  })
]
