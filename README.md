# Bright's NixOS Config

[![Lines of Code](https://img.shields.io/endpoint?url=https%3A%2F%2Ftokei.kojix2.net%2Fbadge%2Fgithub%2Fbright-shard%2Fnixos-config%2Flines)](https://tokei.kojix2.net/github/bright-shard/nixos-config)

The NixOS config I use for my PCs and servers.

Main features:
- Installs TailScale for connecting to my tailnet
- Custom firewall rules that make TailScale work while connected to Mullvad VPN
- Sets up Syncthing for automatic file synchronization with other computers on my tailnet
- For PCs, installs my WM setup (Niri with all my keybinds, apps, theming, etc)
- Building the Nix config for one host builds the config for *all* hosts, allowing:
	- Hosts to read data from each others' Nix config (e.g. their Syncthing IDs, so they automatically add each other in Syncthing)
	- Modifying any part of the config on any machine, then being confident it'll work on all machines
- Has a custom firewall module, for more fine-grained control over which ports are available to LAN, the Tailnet, or entire internet
- Has a work-in-progress (broken) from-scratch container runtime
- Written entirely in stable Nix - no Flakes!



# Usage

For future me when I inevitably forget how this works in 2 weeks. And for the purpose of sharing knowledge.

- Clone this Git repo into `/etc/nixos`
- If this is for a new host:
	- Make a folder for the host in `hosts` with a `default.nix`
	- Generate the hardware configuration for the host: `nixos-generate-config --show-hardware-config > /etc/nixos/hosts/hostname/hardware-configuration.nix`
	- Set whatever host-specific config in `default.nix`. At the very least you'll have to set some options in the `bs` module that enable/disable various parts of this NixOS config.
- Put the hostname in the `HOSTNAME` file
- Build with `nixos-rebuild switch --file /etc/nixos --sudo`
	- Once the config is built, you can just run `cfgupdate` instead - it's aliased to that mouthful
	- `sysupdate` is aliased to the same thing, but it updates dependencies through `npins` before building the new config
- Connect the host to the Tailnet: Run `tailscale login --login-server https://router.brightshard.dev` and follow the onscreen instructions


## Useful Scripts

- Update with a temporary trusted substituter: `cfgupdate --option substituters '["http://<substituter>?trusted=1" "http://<substituter2>?trusted=1"]'`
	- Example to use Brilliance and the standard NixOS cache: `cfgupdate --option substituters '["http://brilliance.bs:5000?trusted=1" "https://cache.nixos.org"]'`
	- This command needs to be run as a Nix trusted user (by default, root is the only trusted user) since it adds a substituter
- Clean old generations: `nix-collect-garbage -d`
- Temporarily disable all substituters: `cfgupdate --option substituters ''`



# Code Layout

Yes, this configuration is *that* big.

- `HOSTNAME` is a gitignore'd file whose sole purpose is to hold the hostname for the machine to install the NixOS config for. This way my config can build the NixOS configurations for all my machines, but then only actually install the config for the current machine.
- `containers/` is not currently used but has NixOS configurations for containers I plan to use once I finish my custom container runtime.
- `home-manager/` has stuff related to `home-manager`.
	- `home-manager/modules/` has my custom `home-manager` modules.
- `hosts/` has configs for all of my hosts. Every computer I own that runs NixOS has its own host in this folder. `hosts/all.nix` has NixOS settings that are set for all hosts.
- `nix/` has stuff related to nixpkgs and NixOS.
	- `nix/deps/` has dependencies (managed through `npins`) and a small `npins` wrapper to automatically import flakes.
	- `nix/modules/` has custom NixOS modules.
	- `nix/overlays/` has my nixpkgs overlays.
- `priv/` has private data that's gitignored so it's not public on GitHub.
- `users/` has home-manager configs for all of the users on my system. `users/all.nix` has home-manager options that are set for all users.
- `configuration.nix` has the base NixOS config that's shared between all hosts and containers.
- `crux.nix` does most of the work in my config. It has some useful constants and utility functions, imports my dependencies from `nix/deps`, and builds the NixOS configs for all of my hosts in the `hosts/` folder. Pretty much every file in my config can then access all those things by just adding `let crux = import ./path/to/crux.nix; in with crux;` line.
- `default.nix` contains a custom NixOS build script that imports `crux.nix` and then returns the NixOS config for the current host. This setup lets me update NixOS with a simple `nixos-rebuild switch --file /etc/nixos --sudo`.
- `HOSTNAME` simply has the hostname of the current host, so `default.nix` returns the NixOS config for the correct host.
