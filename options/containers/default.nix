# Custom containers API, as the default NixOS & systemd-nspawn APIs don't
# provide all the features I want.

{ lib, ... }@args:

let
  inherit (lib) mkOption types;
in

{
  imports = [ ./config.nix ];

  options = {
    bs.containers = mkOption {
      default = { };

      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = import ./options.nix (args // { inherit name; });
          }
        )
      );

      description = ''
        Declarative NixOS containers.


        # What is a Container?

        Containers are kind of a form of lightweight OS-level virtualisation. Similar to VMs, containers can have isolated users/groups, isolated filesystems, and limits set on their hardware usage.

        Containers are more lightweight because they use the same kernel as the host. This imposes some limitations compared to VMs - you can't run a Windows container nor run a container under a different CPU architecture, for example - but means containers have native performance, shared hardware, and take less resources for the host to run than VMs.

        Containers are also generally easier to configure than VMs. You can, for example, let the container share some users with your host, but not access the root account; or access very specific folders on your host, but not every folder; or share a networking stack with your host, but not share users/folders; etc.


        # Declarative Containers

        This NixOS module lets you declaratively control:
        - Whether to share or isolate resources between the container and host (e.g. users or filesystems). All resources are isolated by default to make containers more secure.
        - (Not yet implemented) Hardware limitations on the container (e.g. constraining how much RAM/CPU it can use). Containers have no limitations by default to maximise performance.
        - The NixOS configuration used by the container.


        # Security

        This declarative module is designed such that containers are isolated from the host (but not vice versa).

        Containers declared in this module are completely isolated from the host by default (except for the Nix store). Programs running in the container strictly cannot access anything the host has access to (no files, nor even the network), unless you change settings in the `isolation` module.

        Containers *do* share the Nix store with the host, purely for access to the Nix runtime so the container's Nix configuration can be built. You cannot disable sharing the Nix store in this module, as it assumes you will build the container with a NixOS configuration, which needs access to the Nix store. This means programs in containers can read anything you specify in your NixOS config, flakes, devshells, etc., since that data is inevitably copied to the Nix store.

        So, as long as you don't change any `isolation` settings, and are careful about what you put in the Nix store, containers declared here are reasonably secure by default. There are still a few (very unlikely) ways a malicious program could jailbreak out of these default containers:
        - Exploiting something in the Nix store or runtime
        - Exploiting a kernel vulnerability, as the host and container share the same Linux kernel
        - Exploiting a hardware vulnerability, as the host and container share the same physical CPU and RAM

        Most likely, though, the default container settings do not work for your use case, and you'll need to change some `isolation` settings to make the container work for you. If you change the `isolation` settings, you need to be careful, because you may introduce bugs that can be exploited to perform jailbreaks. Examples include:
        - Mapping the root user in the container to the root user on the host, then running programs as root in the container. Any program running as root in the container will also have root privileges on the host.
        - Mounting host folders to the container, such that the container can write to executable files that are run on the host. The container could inject malware into an executable file that allows it to escape its container once the executable is run on the host.
        - Mounting host folders to the container that leak private information.
        - Granting the container internet/LAN access, which may let it exploit other devices on your network or view services exposed on ports on your host.

        Obviously this is not an complete nor extensive list of potential container vulnerabilies; they're just examples to get you thinking about container security.

        Depending on your use case you may not care about these security vulnerablities. If you're okay with running the software in the container on your host system with the same permissions, then you may not need any of the isolation features of containers (I'm also not sure why you'd be using containers in the first place).

        Here's some links for more information about container security. Note that these resources are mostly written for other software providing containers (e.g. Docker, Podman, LXC) and may have details that don't apply to this NixOS module.
        - https://linuxcontainers.org/lxc/security/
        - https://securitylabs.datadoghq.com/articles/container-security-fundamentals-part-1/
      '';
    };
  };
}
