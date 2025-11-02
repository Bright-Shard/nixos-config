{ crux, pkgs, ... }:

with crux;

{
  bs = {
    gui = false;
    syncthingId = "JU2AJV4-X66ZQKW-M7JXNXZ-MW562LB-JF7WN4U-2ITMK6F-E4XYWBB-HIEFVQE";
    mullvad = false;
    # Ports we want to expose to the public internet
    firewall = {
      # So many bots online that if we log every violation it just fills up
      # systemd logs and I can't find anything useful...
      logViolations = false;
      openGlobalPorts.tcp = [
        18080 # Monero node
        37889 # p2pool node
      ];
      openInterfacePorts = {
        # Ports to expose to my tailnet
        tailscale0 = {
          tcp = [
            18081 # Monero node RPC
            3333 # p2pool Stratum
            5000 # Nix binary cache
            25565 # Minecraft server
          ];
          udp = [
            24454 # Proximity chat for Minecraft server
          ];
        };
        # Ports to expose to the entire internet
        hoppy = {
          tcp = [
            25565 # Minecraft server
            443 # Headscale
            80 # Headscale ACME challenge
          ];
          udp = [
            24454 # Proximity chat for Minecraft server
          ];
        };
      };
    };
  };

  fileSystems = {
    "/external/500gb" = {
      device = "/dev/disk/by-partuuid/294976ec-c6a8-414f-86e8-a446e05cfeb0";
      fsType = "ext4";
    };
  };
  hardware.amdgpu.opencl.enable = true;

  # Connect to my hoppy.network server for port forwarding
  networking.wireguard.interfaces.hoppy = PRIV.HOPPY;

  # Self-hosted shit
  services = {
    nix-serve.enable = true;

    headscale = {
      enable = true;
      port = 443;
      settings = {
        server_url = "https://router.brightshard.dev";
        listen_addr = "0.0.0.0:443";
        tls_letsencrypt_hostname = "router.brightshard.dev";
        acme_email = "brightshard@brightshard.dev";
        dns = {
          base_domain = "bs";
          nameservers.global = [
            # Mullvad's encrypted DNS
            # https://mullvad.net/en/help/dns-over-https-and-dns-over-tls
            "194.242.2.2"
          ];
        };
      };
    };

    monero = {
      enable = true;
      prune = true;
      rpc = {
        address = "0.0.0.0";
        port = 18081;
      };
      extraConfig = ''
        no-igd=1
        hide-my-port=1
        confirm-external-bind=1
        zmq-pub=tcp://127.0.0.1:18083
        enforce-dns-checkpointing=1
        enable-dns-blocklist=1
      '';
    };
    xmrig = {
      enable = false;
      settings = {
        autosave = false;
        cpu = {
          enabled = true;
          asm = "ryzen";
          max-threads-hint = 80;
        };
        opencl = {
          enabled = true;
          loader = "${pkgs.rocmPackages.clr}/lib/libOpenCL.so";
        };
        pools = [
          {
            coin = "monero";
            url = "brilliance.bs:3333";
          }
        ];
      };
    };
    p2pool = {
      enable = true;
      settings = {
        wallet = "46rDP6RQ8VaMj1DhCjNcgdJwuscdW6eguNDvagng7qKoHxiBrAhU6M4fRBmNT7ioMrYaPD7bxZxkYgy6MzvGkrCT3sNtfKZ";
        chain = "mini";
        stratum.host = "0.0.0.0";
        p2p.host = "0.0.0.0";
      };
    };
  };
  systemd.services = {
    # xmrig.wants = [ "p2pool.service" ];
    monero.wants = [ "tailscaled.service" ];
  };

  # Let Headscale bind ports <1000
  systemd.services.headscale.serviceConfig.AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];

  # Minecwaft
  systemd.services.lads-mc-server = {
    enable = true;
    after = [ "network.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "simple";
      WorkingDirectory = "/srv/mc-servers/lads";
      ExecStart = "${pkgs.bash}/bin/bash --login run.sh";
      User = "mc-server";
      Group = "mc-server";
    };
  };
  users = {
    users.mc-server = {
      isSystemUser = true;
      group = "mc-server";
      home = "/srv/mc-servers";
      createHome = true;
      packages = with pkgs; [ jdk ];
    };
    groups.mc-server = { };
  };

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
