{
  crux,
  pkgs,
  config,
  ...
}:

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
        80 # Caddy
        443 # Caddy
      ];
      openInterfacePorts = {
        # Ports to expose to my tailnet
        tailscale0 = {
          tcp = [
            18081 # Monero node RPC
            3333 # p2pool Stratum
            5000 # Nix binary cache
            25565 # Minecraft server
            8080 # Nextcloud
          ];
          udp = [
            24454 # Proximity chat for Minecraft server
          ];
        };
        # Ports to expose to the entire internet
        hoppy = {
          tcp = [
            25565 # Minecraft server
          ];
          udp = [
            24454 # Proximity chat for Minecraft server
          ];
        };
      };
    };
    state-version = "25.11";
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

  services.nix-serve = {
    enable = true;
    secretKeyFile = "/srv/nix/private-key.pem";
  };

  services.caddy = {
    enable = true;
    extraConfig = ''
      # just in case i want it later...
      #@tailnet ${RESERVED-IPS.IPv4.CARRIER-GRADE-NAT}

      # Headscale
      router.brightshard.dev {
      	reverse_proxy http://localhost:${toString config.services.headscale.port}
      }

      # Static file server
      # The file server listens on port 2001. Firewall settings guarantee this
      # port isn't exposed on any interfaces.
      # When you visit static.brightshard.dev, you get sent to Anubis. Anubis
      # then proxies traffic back to the static file server. Anubis can connect
      # to the file server because it can access localhost.
      # This setup guarantees all traffic has to go through Anubis before being
      # able to access the static file server.
      http://static.brightshard.dev:2001 {
      	root /srv/static
      	file_server browse
      }
      static.brightshard.dev {
        reverse_proxy http://localhost:2000 {
          header_up X-Real-Ip {remote_host}
          header_up X-Http-Version {http.request.proto}
        }
      }

      # Nextcloud
      http://cloud.bs {
        redir http://cloud.bs:8080{uri} permanent
      }
    '';
    dataDir = "/srv/caddy";
    email = "brightshard@brightshard.dev";
  };
  # Let Caddy bind ports <1024
  systemd.services.caddy.serviceConfig.AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
  # Ensure the static file storage folder is available
  systemd.tmpfiles.settings."11-srv-static"."/srv/static".d = {
    user = "caddy";
    group = "caddy";
  };

  # Anubis, anti-bot anti-scraper software
  # I host large files sometimes so I'd rather those not get downloaded a
  # million times and eat my processing power
  # Port mapping:
  # - Anubis listens on 2000
  # - It forwards to 2001
  # - Caddy picks things back up at 2001
  services.anubis = {
    defaultOptions = {
      settings = {
        SERVE_ROBOTS_TXT = true;
        WEBMASTER_EMAIL = "webmaster@brightshard.dev";
        OG_PASSTHROUGH = true;
        BIND_NETWORK = "tcp";
      };
      botPolicy = {
        bots = [
          { import = "(data)/common/keep-internet-working.yaml"; }
          { import = "(data)/meta/ai-block-aggressive.yaml"; }
          {
            name = "challenge";
            path_regex = ".*";
            action = "CHALLENGE";
          }
        ];
      };
    };
    instances.main.settings = {
      TARGET = "http://localhost:2001";
      BIND = ":2000";
    };
  };

  services.headscale = {
    enable = true;
    port = 4000;
    settings = {
      server_url = "http://router.brightshard.dev";
      dns = {
        base_domain = "bs";
        nameservers.global = [
          # Mullvad's encrypted DNS
          # https://mullvad.net/en/help/dns-over-https-and-dns-over-tls
          "194.242.2.2"
        ];
        extra_records = [
          {
            name = "cloud.bs";
            type = "A";
            value = "100.64.0.3";
          }
        ];
      };
    };
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    configureRedis = true;
    home = "/srv/nextcloud";
    autoUpdateApps.enable = true;
    hostName = "cloud.bs";
    config = {
      adminpassFile = toString ../../default-pass.txt;
      dbtype = "pgsql";
    };
    database.createLocally = true;
  };
  # nextcloud uses nginx... which conflicts with caddy...
  services.nginx.defaultHTTPListenPort = 8080;
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    user = "ollama";
    group = "ollama";
    host = "0.0.0.0";
    loadModels = [
      "qwen3:8b"
      "qwen3:1.7b"
    ];
  };

  # Crypto
  services = {
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

  # Services not included in NixOS
  systemd.services = {
    # Minecwaft
    lads-mc-server = {
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
    "49sd-bot" =
      let
        python = with pkgs; python313.withPackages (pypkgs: with pypkgs; [ discordpy ]);
      in
      {
        enable = true;
        after = [ "network.target" ];
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "simple";
          WorkingDirectory = "/srv/discord-bots/49sd";
          ExecStart = "${python}/bin/python3 main.py";
          User = "discord";
          Group = "discord";
        };
      };
  };

  # Users for self-hosting shit so I can limit permissions
  users = {
    users = {
      mc-server = {
        isSystemUser = true;
        group = "mc-server";
        home = "/srv/mc-servers";
        createHome = true;
        packages = with pkgs; [ jdk ];
      };
      discord = {
        isSystemUser = true;
        group = "discord";
        home = "/srv/discord-bots";
        createHome = true;
      };
      caddy = {
        home = "/srv/caddy";
        createHome = true;
      };
    };
    groups = {
      mc-server = { };
      discord = { };
    };
  };
}
