# Globals & constants everything else imports

with builtins;

builtins
// rec {
  # Public keys
  KEYS = {
    PGP-PUBLIC = ''
      -----BEGIN PGP PUBLIC KEY BLOCK-----

      mDMEZifSfxYJKwYBBAHaRw8BAQdASlxw0OM7dEjqzAERkJP5nIYM3XSOSabet7/U
      9wmqCQu0KUJyaWdodFNoYXJkIDxicmlnaHRzaGFyZEBicmlnaHRzaGFyZC5kZXY+
      iJMEExYKADsWIQToeVhSRVc3z/wDPOrcLK+wpsM2MAUCZifSfwIbIwULCQgHAgIi
      AgYVCgkICwIEFgIDAQIeBwIXgAAKCRDcLK+wpsM2MBXPAP9v0pHbWpxyItf2usbU
      aPWlHnPLn2luLW1L+hiUVQe4uAEAvhILeXFxfbfeIa+FbaP64zdD7RJPv2Yp8nF6
      9FycngC4OARmJ9LFEgorBgEEAZdVAQUBAQdA22y9EW2k74nVb6oBYEfZ92R7oysR
      dD6mdb9B4FXqrEkDAQgHiHgEGBYKACAWIQToeVhSRVc3z/wDPOrcLK+wpsM2MAUC
      ZifSxQIbDAAKCRDcLK+wpsM2MBhQAP9JZUlhQS10JT8Au5OOwYfG3xy1yIUWD1NQ
      65gCV0OU3wEAl12c8eyHbikNQpa1KpE4bALqYcMONkEgParBQz5hgwc==hJcS

      -----END PGP PUBLIC KEY BLOCK-----
    '';
    PGP-GPG-ID = "DC2CAFB0A6C33630";
    SSH-PUBLIC = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpccNDjO3RI6swBEZCT+ZyGDN10jkmm3re/1PcJqgkL";
    SSH-GPG-ID = "A79C716EC11610D2";
  };

  # UI options
  THEME = {
    CATPPUCCIN_FLAVOR = "frappe";
    CATPPUCCIN_ACCENT = "yellow";
    CODE_FONT = "ShureTechMono Nerd Font Propo";
  };

  # Private data I don't want stored on GitHub
  # You can still see `priv/default.nix` for what kind of data is stored, though
  PRIV = import ./priv;

  # External deps
  DEPS = import ./nix/deps;
  PKGS = DEPS.nixpkgs.legacyPackages.${currentSystem};

  # This entire NixOS config, stored in the NixOS store
  FILESET =
    with PKGS.lib.fileset;
    let
      blacklist = [
        ./.git
        ./.stfolder
        ./.stignore
        ./.gitignore
      ];
    in
    toSource {
      root = ./.;
      fileset = fileFilter (file: !elem file blacklist) ./.;
    };

  # Hostname of the machine building the NixOS config
  NATIVE-HOSTNAME = replaceStrings [ "\n" ] [ "" ] (readFile ./HOSTNAME);

  # The NixOS configs for all hosts in `hosts/`
  HOSTS =
    let
      hostNames = readSubdirs ./hosts;
      buildCfg =
        hostname:
        DEPS.nixpkgs.lib.nixosSystem {
          system = builtins.currentSystem;
          specialArgs = {
            crux = (import ./crux.nix) // {
              HOSTNAME = hostname;
            };
          };
          modules = concatLists [
            (map (module: ./nix/modules/${module}) (attrNames (readDir ./nix/modules)))

            (with DEPS; [
              nixos-apple-silicon.nixosModules.apple-silicon-support
              home-manager.nixosModules.home-manager
              catppuccin.nixosModules.catppuccin
              nix-flatpak.nixosModules.nix-flatpak
              nix-minecraft.nixosModules.minecraft-servers
            ])

            [
              ./configuration.nix
              ./hosts/all.nix
              ./hosts/${hostname}
              ./hosts/${hostname}/hardware-configuration.nix
            ]
          ];
        };
      mkHost = hostName: {
        name = hostName;
        value = buildCfg hostName;
      };
    in
    listToAttrs (map mkHost hostNames);

  # Returns a list of all subdirectories in the given path.
  readSubdirs =
    path:
    let
      dirEntries = readDir path;
    in
    filter (entry: dirEntries.${entry} == "directory") (attrNames dirEntries);
  inherit (PKGS.lib) mkMerge mkIf;

  # IANA reserved IP addresses
  # Useful both as notes and for firewall rules
  RESERVED-IPS = {
    IPv4 = {
      LAN = [
        "10.0.0.0/8" # 10.0.0.0 - 10.255.255.255
        "172.16.0.0/12" # 172.16.0.0 - 172.31.255.255
        "192.168.0.0/16" # 172.168.0.0 - 192.168.255.255
      ];
      # According to Wikipedia:
      # > Used for benchmark testing of inter-network communications between
      # > two separate subnets.
      INTER-LAN-BENCHMARKS = "198.18.0.0/15"; # 198.18.0.0 - 198.19.255.255
      # LAN addresses for ISPs
      CARRIER-GRADE-NAT = "100.64.0.0/10"; # 100.64.0.0 - 100.127.255.255
      LOOPBACK = "127.0.0.0/8"; # 127.0.0.0-127.255.255.255
      # Protocol allowing IPv4 packets to be sent over IPv6
      DS-LITE = "192.0.0.0/24"; # 192.0.0.0 - 192.0.0.255
      DOCS-AND-EXAMPLES = [
        "192.0.2.0/24" # 192.0.2.0 - 192.0.2.255
        "198.51.100.0/24"
        "203.0.113.0/24"
        # Actually part of the MULTICAST range, but still just for docs
        "233.252.0.0/24"
      ];
      RESERVED = [
        # According to Wikipedia this *was* used for IPv6 to IPv4 relays but is
        # now just reserved.
        "192.88.99.0/24"
        # According to Wikipedia this *was* used for Class E networks but is now
        # just reserved.
        "240.0.0.0/4"
      ];
      LINK-LOCAL = "169.254.0.0/16"; # 169.254.0.0 - 169.254.255.255
      MULTICAST = "224.0.0.0/4"; # 224.0.0.0 - 239.255.255.255
      BROADCAST = "255.255.255.255/32";
    };
    # Note: I use `...` to represent that the rest of the address is just
    # `FFFF` segments, like how `::` represents the rest of the address is
    # `0000` segments.
    IPv6 = {
      UNSPECIFIED = "::/128";
      LOOPBACK = "::1/128";
      # Last two sections store the IPv4 address, e.g.
      # ::FFFF:0:0 -> ::FFFF:0.0.0.0 -> 0.0.0.0
      # ::FFFF:FF00:00FF -> ::FFFF:255.0.0.255 -> 255.0.0.255
      IPv4-MAPPED = "::FFFF:0:0/96"; # ::FFFF:0:0 - ::FFFF:FFFF:FFFF
      # Public NAT-like translation service between IPv6 and IPv4
      # Provide the IPv4 address in the last 4 bytes (like with IPv4-MAPPED)
      # and the router will route to that address for you
      NAT64 = "64:FF9B::/96"; # 64:FF9B::0:0 - 64:FF9B::FFFF:FFFF
      # Wikipedia describes this as:
      # > local-use IPv4/IPv6 translation
      # So, NAT64 for LANs?
      LOCAL-NAT64 = "64:FF9B:1::/48"; # 64:FF9B:1:: - 64:FF9B:1:...
      # Protocol developed by Microsoft to give IPv6 access to devices on IPv4
      # only networks
      TEREDO-TUNNELING = "2001::/32"; # 2001:: - 2001:0:...
      # I can't figure out what this is but it seems to be reserved for
      # protocols like HIP, which seem to be protocols that allow hosts to
      # communicate without knowing each others' IP addresses
      ORCHID = "2001:20::/28"; # 2001:20:: - 2001:2f:...
      DOCS-AND-EXAMPLES = [
        "2001:db8::/32" # 2001:db8:: - 2001:db8:...
        "2FFF::/20" # 3FFF:: - 3FFF:...
      ];
      # Protocol that allows IPv6 packets to be sent over IPv6, like Toledo
      # tunneling
      SIX-TO-FOUR = "2002::/16"; # 2002:: - 2002:...
      SEGMENT-ROUTING = "5F00::/16"; # 5F00:: - 5F00:...
      # A unique address only accessible from the local network
      UNIQUE-LOCAL-ADDRESS = "FC00::/7"; # FC00:: - FDFF:...
      # An address for a specific link on a network interface
      LINK-LOCAL-ADDRESS = "FE80::/64"; # FE80:: - FE80::FFFF:FFFF:FFFF:FFFF
      GLOBAL-MULTICAST-ADDRESS = "FF00::/8"; # FF00:: - ...
    };
  };
}
