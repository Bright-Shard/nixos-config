{ crux, ... }:

with crux;

# Cybersecurity-oriented shell
# Containerised so it has its own networking stack, e.g. the container can connect to HTB/THM VPNs without my whole system having to go through the VPN
# Also allows me to have cybersecurity tools installed, but isolated, so they don't blow up tab-complete (since there's a lot of them)
{
  autoStart = true;

  config.module.config =
    { lib, pkgs, ... }:

    {
      environment = {
        systemPackages =
          with pkgs;
          [
            # Non-Hacking Utils
            git
            busybox
            bat
            openvpn
            p7zip

            # Enumeration
            nmap
            ffuf
            gobuster

            # Exploitation
            exploitdb
            sqlmap

            # Post-Exploitation
            sshuttle

            # Password Cracking
            hashcat
            hashcat-utils
            maskprocessor
            john
            wordlists
            ares-rs

            # Reverse Engineering
            binaryninja-free
            binwalk

            # General Purpose
            metasploit
            burpsuite
            netcat
            steghide
          ]
          ++ map (pkg: pkgs.callPackage ./pkgs/${pkg} { }) (attrNames (readDir ./pkgs));
      };

      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "binaryninja-free"
          "burpsuite"
          "ida-pro"
        ];

      programs = {
        zsh.enable = true;
        vim = {
          enable = true;
          defaultEditor = true;
        };
        wireshark.enable = true;
      };

      system.stateVersion = "25.11";
    };
}
