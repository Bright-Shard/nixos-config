# Bright's NixOS Config

[![Lines of Code](https://img.shields.io/endpoint?url=https%3A%2F%2Ftokei.kojix2.net%2Fbadge%2Fgithub%2Fbright-shard2%2Fnixos-config%2Flines)](https://tokei.kojix2.net/github/bright-shard/nixos-config)

A (work-in-progress) customizable NixOS config I use for my PCs and servers.

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



# Code Layout

Yes, this configuration is *that* big.

- `HOSTNAME` is a gitignore'd file whose sole purpose is to hold the hostname for the machine to install the NixOS config for. This way my config can build the NixOS configurations for all my machines, but then only actually install the config for the current machine.
- `default.nix` contains a custom build script. It builds the NixOS configs for all hosts and makes that available to the hosts' NixOS configs via the `BUILD-META.HOSTS` variable. It also imports all my `npins` dependencies.
- `kernel.nix` has a custom package set for the [Linux hardened]() kernel, since the one in nixpkgs is very much out of date (and my Framework Desktop really needs the latest kernel version).
- `crux.nix` has constants and utility functions that get glob imported in all the configuration files (e.g. every file starts off with a `with crux;` statement).
- `nixpkgs/` has a custom nixpkgs overlay. There isn't much in there for now; it's mostly just there so I have a place for overlays in the future.
- `npins/` is just the folder for [npins](https://github.com/andir/npins), a program that lets me pin dependencies without using Flakes. I prefer npins since it lets me depend on non-Flakes (while Flakes can only depend on other Flakes), and I also encountered some odd bugs with Flakes that I don't have in stable Nix.
- `priv/` is a gitignore'd folder. From GitHub, you can only see `priv/default.nix`, which imports private data from other files in the `priv` folder.
- `users/` has home-manager configurations for users on my system. `users/configuration.nix` has globale home-manager configurations that apply to all users.
- `programs/` is not currently used; the plan is to house larger program settings in their own modules there.
- `options/` has custom modules I've added on top of the standard NixOS configuration options. It has some overridden defaults for standard NixOS options, adds a custom firewall module, lets you customize what features from this config are included for a specific host, and also has a work-in-progress custom container runtime.
- `hosts/` has per-host NixOS configurations. `hosts/configuration.nix` has global configurations that apply for all hosts (this differs from `configuration.nix` because those settings will also apply for containers, once I finish my container runtime).
- `containers/` is not currently used but has NixOS configurations for containers I plan to use once I finish my custom container runtime.
