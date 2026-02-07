{
  crux,
  pkgs,
  config,
  lib,
  ...
}:

with crux;

let
  # Tracks which services use which port
  # Normally I could use `config.services.<servicename>.port`, but some services
  # don't have that option (e.g. services I made in systemd directly or
  # services that aren't from nixpkgs and don't have the standard nixpkgs
  # options)
  PORTS_INT = {
    anubis = 2000;
    anubisPassed = 2001;

    pds = 3000;
    tangled = {
      knot = 3001;
      knotInternal = 3002;
      appview = 3003;
      spindle = 3004;
    };

    headscale = 4000;
  };
  PORTS =
    let
      stringify = attrs: mapAttrs (k: v: if typeOf v == "set" then stringify v else toString v) attrs;
    in
    stringify PORTS_INT;

in

lib.mkMerge [
  # The system itself
  {
    bs = {
      gui = true;
      mod = "Ctrl";
      altMod = "Alt + Ctrl";
      syncthingId = "JU2AJV4-X66ZQKW-M7JXNXZ-MW562LB-JF7WN4U-2ITMK6F-E4XYWBB-HIEFVQE";
      mullvad = false;
      state-version = "25.11";
    };

    fileSystems = {
      "/external/500gb" = {
        device = "/dev/disk/by-partuuid/294976ec-c6a8-414f-86e8-a446e05cfeb0";
        fsType = "ext4";
      };
    };
    hardware = {
      amdgpu.opencl.enable = true;
      bluetooth.enable = true;
    };
  }

  # Firewall, routing, etc. for self-hosted services
  {
    # Connect to my hoppy.network server for port forwarding
    networking.wireguard.interfaces.hoppy = PRIV.HOPPY;

    bs.firewall = {
      # Ports open on every interface
      openGlobalPorts = {
        tcp = [
          18080 # Monero node
          37889 # p2pool node
          80 # Caddy
          443 # Caddy
          25565 # Minecraft server
          25566 # avr Minecraft server
        ];
        udp = [
          24454 # Proximity chat for Minecraft server
          5520 # Hytale btw
        ];
      };
      openInterfacePorts = {
        # Ports to expose to my tailnet
        tailscale0 = {
          tcp = [
            18081 # Monero node RPC
            3333 # p2pool Stratum
            5000 # Nix binary cache
          ];
          udp = [ ];
        };
        # Ports to expose only to the internet
        hoppy = {
          tcp = [ ];
          udp = [ ];
        };
      };

      # So many bots online that if we log every violation it just fills up
      # systemd logs and I can't find anything useful...
      logViolations = false;
    };

    # I use Caddy to route requests from different services
    services.caddy = with PORTS; {
      enable = true;
      extraConfig = ''
        # Headscale
        router.brightshard.dev {
        	reverse_proxy http://localhost:${headscale}
        }

        # Static file server, protected by Anubis
        # See comments above the Anubis cfg for how this works
        http://static.brightshard.dev:${anubisPassed} {
         	root /srv/static
         	file_server browse
        }
        static.brightshard.dev {
          reverse_proxy http://localhost:${anubis} {
            header_up X-Real-Ip {remote_host}
            header_up X-Http-Version {http.request.proto}
          }
        }

        # atproto services
        pds.brightshard.dev {
          reverse_proxy http://localhost:${pds}
        }
        http://git.brightshard.dev:${anubisPassed} {
          reverse_proxy http://localhost:${tangled.appview}
        }
        git.brightshard.dev/oauth/* {
          reverse_proxy http://localhost:${tangled.appview}
        }
        git.brightshard.dev {
          reverse_proxy http://localhost:${anubis} {
            header_up X-Real-Ip {remote_host}
            header_up X-Http-Version {http.request.proto}
          }
        }
        knot.tangled.brightshard.dev {
          reverse_proxy http://localhost:${tangled.knot}
        }
        knot.tangled.brightshard.dev/events {
          reverse_proxy http://localhost:${tangled.knot} {
            header_up X-Forwaded-For {remote_host}
            header_up Upgrade websocket
            header_up Connection Upgrade
          }
        }
        spindle.tangled.brightshard.dev {
          reverse_proxy http://localhost:${tangled.spindle}
        }
        spindle.tangled.brightshard.dev/events {
          reverse_proxy http://localhost:${tangled.spindle} {
            header_up X-Forwaded-For {remote_host}
            header_up Upgrade websocket
            header_up Connection Upgrade
          }
        }
      '';
      dataDir = "/srv/caddy";
      email = "brightshard@brightshard.dev";
    };
    # Allow Caddy to bind privileged ports
    systemd.services.caddy.serviceConfig.AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];

    # Anubis, anti-bot & anti-scraper software
    # The basic system is:
    # - Caddy receives an HTTPS request on 443
    # - Caddy forwards the request to Anubis on port 2000
    # - If Anubis validates the request, it sends it back to Caddy on port 2001
    # - Caddy then routes the request to the correct service
    #
    # Ports 2000 & 2001 aren't exposed to the internet (thanks to my firewall
    # rules). So this setup ensures all requests have to go through Anubis
    # before routing to their actual HTTP server.
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
        TARGET = "http://localhost:${PORTS.anubisPassed}";
        BIND = ":${PORTS.anubis}";
      };
    };
  }

  # atproto services
  # Allocated ports 3000->3100
  {
    services = {
      bluesky-pds = {
        enable = true;
        settings = rec {
          PDS_PORT = 3000;
          PDS_HOSTNAME = "pds.brightshard.dev";
          PDS_ADMIN_EMAIL = "pds@brightshard.dev";
          PDS_DATA_DIRECTORY = "/srv/pds";
          STATE_DIRECTORY = PDS_DATA_DIRECTORY;
          PDS_BLOBSTORE_DISK_LOCATION = "${PDS_DATA_DIRECTORY}/blocks";
          PDS_BLOBSTORE_DISK_TMP_LOCATION = "/tmp/pds-blockstore-tmp";
          PDS_ACCOUNT_DB_LOCATION = "${PDS_DATA_DIRECTORY}/account.sqlite";
          PDS_SEQUENCER_DB_LOCATION = "${PDS_DATA_DIRECTORY}/sequencer.sqlite";
          PDS_DID_CACHE_DB_LOCATION = "${PDS_DATA_DIRECTORY}/did_cache.sqlite";
          PDS_INVITE_REQUIRED = "true";
        };
        environmentFiles = [ "/srv/pds/.env" ];
      };

      tangled =
        let
          dataDir = "/srv/tangled";
          owner = "did:plc:knlrj2kb4xvwhx7ugip6e6p2";
        in
        {
          knot = {
            enable = true;
            # appviewEndpoint = appviewUrl;
            appviewEndpoint = "https://tangled.org";
            openFirewall = false; # I manage it myself
            stateDir = dataDir;
            server = {
              listenAddr = "localhost:${PORTS.tangled.knot}";
              internalListenAddr = "localhost:${PORTS.tangled.knotInternal}";
              hostname = "knot.tangled.brightshard.dev";
              inherit owner;
            };
          };
          appview = {
            enable = false;
            port = PORTS_INT.tangled.appview;
            listenAddr = "localhost:${PORTS.tangled.appview}";
            dbPath = "${dataDir}/appview.db";
            appviewHost = "git.brightshard.dev";
            appviewName = "BrightShard's Tangled Instance";
            environmentFile = "${dataDir}/appview.env";
          };
          spindle = {
            enable = true;
            server = {
              listenAddr = "localhost:${PORTS.tangled.spindle}";
              dbPath = "${dataDir}/spindle.db";
              hostname = "spindle.tangled.brightshard.dev";
              inherit owner;
              maxJobCount = 8;
            };
          };
        };
    };
    systemd.services =
      let
        tangledCfg = {
          User = "git";
          Group = "git";
          WorkingDirectory = lib.mkForce "/srv/tangled";
          ReadWritePaths = lib.mkForce [ "/srv/tangled" ];
        };
      in
      {
        bluesky-pds =
          let
            dataDir = config.services.bluesky-pds.settings.PDS_DATA_DIRECTORY;
          in
          {
            serviceConfig = {
              User = "pds";
              Group = "pds";
              StateDirectory = lib.mkForce null;
            };
            unitConfig.RequiresMountsFor = dataDir;
          };
        knot.serviceConfig = tangledCfg;
        # appview.serviceConfig = tangledCfg;
        spindle.serviceConfig = tangledCfg;
      };
  }

  # Headscale
  {
    services.headscale = {
      enable = true;
      port = PORTS_INT.headscale;
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
  }

  # Crypto
  {
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
  }

  # Misc services
  {
    # Nix binary cache
    services.nix-serve = {
      enable = true;
      secretKeyFile = "/srv/nix/private-key.pem";
    };

    # Folder for the static file server
    systemd.tmpfiles.settings."11-srv-static"."/srv/static".d = {
      user = "caddy";
      group = "caddy";
    };

    services.minecraft-servers = {
      enable = true;
      eula = true;
      openFirewall = false;

      user = "mc-server";
      group = "mc-server";
      dataDir = "/srv/mc-servers";
      managementSystem.tmux = {
        enable = true;
        socketPath = name: "/srv/mc-servers/${name}.sock";
      };

      servers.avr = {
        enable = true;
        package = pkgs.minecraftServers.vanilla;
        whitelist = PRIV.MC.AVR.WHITELIST;
        operators = PRIV.MC.AVR.OPS;
        serverProperties = {
          white-list = true;
          enforce-whitelist = true;
          server-port = 25566;
          spawn-protection = -1;
        };
      };
    };

    # These don't have built-in NixOS modules
    systemd.services =
      mapAttrs
        (
          k: v:
          v
          // {
            after = [ "network.target" ];
            wantedBy = [ "default.target" ];
          }
        )
        {
          # Minecwaft
          lads-mc-server = {
            enable = false;
            serviceConfig = {
              Type = "simple";
              WorkingDirectory = "/srv/mc-servers/lads";
              ExecStart = "${pkgs.bash}/bin/bash --login run.sh";
              User = "mc-server";
              Group = "mc-server";
            };
          };
          avr-mc-server = {
            enable = false;
            serviceConfig = {
              Type = "simple";
              WorkingDirectory = "/srv/mc-servers/avr";
              ExecStart = "${pkgs.bash}/bin/bash --login run.sh";
              User = "mc-server";
              Group = "mc-server";
            };
          };
          hytale-server = {
            enable = true;
            serviceConfig = {
              Type = "simple";
              WorkingDirectory = "/srv/hytale";
              ExecStart = "${pkgs.javaPackages.compiler.temurin-bin.jre-25}/bin/java -Xlog:aot -XX:AOTCache=Server/HytaleServer.aot -jar Server/HytaleServer.jar --assets Assets.zip --bind 173.211.12.135:5520";
              User = "hytale";
              Group = "hytale";
            };
          };
          "49sd-bot" =
            let
              python = with pkgs; python313.withPackages (pypkgs: with pypkgs; [ discordpy ]);
            in
            {
              enable = true;
              serviceConfig = {
                Type = "simple";
                WorkingDirectory = "/srv/discord-bots/49sd";
                ExecStart = "${python}/bin/python3 main.py";
                User = "discord";
                Group = "discord";
              };
            };
        };

    # Per-service users, allowing for more fine-grained permissions
    users =
      let
        u = name: home: {
          name = name;
          value = {
            isSystemUser = true;
            group = name;
            home = lib.mkDefault "/srv/${home}";
            createHome = true;
          };
        };
        SERVICE_USERS = listToAttrs [
          (u "mc-server" "mc-servers")
          (u "caddy" "caddy")
          (u "discord" "discord-bots")
          (u "hytale" "hytale")
          (u "git" "git")
          (u "pds" "pds")
        ];
      in
      lib.mkMerge [
        {
          users = SERVICE_USERS;
          groups = mapAttrs (name: value: { }) SERVICE_USERS;
        }

        {
          # Additional user packages
          users = with pkgs; {
            git.packages = [ tangled.goat ];
            pds.packages = [ atproto-goat ];
          };
        }
      ];
  }

  # Guest user & GUI
  {
    services = {
      desktopManager.plasma6.enable = true;
      displayManager = {
        enable = true;
        sddm = {
          enable = true;
          autoNumlock = true;
          autoLogin.relogin = true;
          wayland = {
            enable = true;
            compositor = "kwin";
          };
        };
        autoLogin.user = "guest";
        defaultSession = "plasma";
      };
    };
    users = {
      users.guest = {
        isNormalUser = true;
        group = "guest";
        password = "";
      };
      groups.guest = { };
    };
    systemd.sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  }
]
