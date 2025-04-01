# Bright's NixOS Config

A (work-in-progress) customizable NixOS config I use for my PCs and servers.

The config automatically:
- Installs TailScale, for connecting to my intranet
- Installs Syncthing, for file synchronization with other computers on my intranet
	- It's configured to sync specific folders with computers on my intranet OOTB
- For PCs, installs my complete Linux setup (Hyprland, IDE, Steam, etc.) in a user named `bs`

There's a blog post about the motivations behind my config and my new setup with Nix + TailScale + Syncthing coming soon:tm:.



# Usage

For future me when I inevitably forget how this works in 2 weeks. But feel free to follow these steps if you're forking this to use in your own setup. Or if you just want to steal my setup for whatever reason.

- Switch to NixOS unstable: `nix-channel --add https://nixos.org/channels/nixos-unstable nixos; nix-channel --update`
- Come up with a unique hostname for the system
	- You can see already taken hostnames in the `hosts` folder
- Put the system's hostname in the `HOSTNAME` file
- Create the host folder:
	- Make a folder in `hosts`, named exactly the same as the hostname you put in `HOSTNAME`
	- Put the `hardware-configuration.nix` file that the NixOS installer generates in that host folder
	- Create a `default.nix` file in that host folder
- Setup `default.nix` (the file created in the last step):
	- This config will automatically import `default.nix`, so think of it like your new `configuration.nix`.
	- Note that `default.nix` is only loaded on a host-per-host basis. So settings you put in there are only loaded for your host, and don't affect any other machines.
	- It's a Nix module, so it has to be a function that accepts arguments and returns an attribute set. That means at the very least the file must contain `{...}: {}`; if it's empty Nix will fail to compile the config.
	- You'll probably want to set `hostOptions` in the config. Set `hostOptions.nix` for options.
- Install NixOS (or run `nixos-rebuild --switch` if installing on top of an existing NixOS setup)
- Set the password for the `bs` user
- Boot into the new install!

If you're wanting to connect this host to the intranet, you'll need to run `tailscale up --login-server https://ts.brightshard.dev`. Then set `hostOptions.syncthingId` to the host's Syncthing ID.
