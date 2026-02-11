{
  lib,
  name,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;
in

{
  autoStart = mkOption {
    default = false;
    type = types.bool;
    description = "Controls whether the container should start automatically when the computer boots.";
    example = true;
  };
  persistent = mkOption {
    default = true;
    type = types.bool;
    description = "Controls file persistence. When enabled, the container keeps all of its files between runs. When disabled, the container will lose all of its files (except any files mounted to the host) as soon as it stops running.";
    example = false;
  };
  isolation = mkOption {
    default = { };
    type = types.submodule (
      { ... }:
      let
        uid-gid-mapping = mkOption {
          default = [ "0:1000:65536" ];
          type = types.listOf types.str;
          description = ''
            Controls how users/groups are mapped between the host and container. This allows:
            - Mapping all users/groups in the container to all users/groups in the host. The root user in the container would be the same as the root user in the host, as would any other users.
            - Mapping specific users/groups in the container to the same users/groups in the host. For example, you could map your normal user to be the same user in the container and host, but make the root user in the container separate from the root user in the host.

            The format is `<base_container_id> <base_host_id> <len>`, where users/groups from `<base_container_id>` to `<base_container_id> + <len>` in the container get translated to `<base_host_id> + <len>` in the host. For example, in `userMaps`:
            - `0:0:1` maps the root user in the container to the root user on the host. One user - user `0`, root - in the container is mapped to one user - again `0`/root - in the host.
            - `0:1000:1` maps the root user in the container to user `1000` on the host.
            - `0:0:1000` maps the first 1000 users in the container to be the same users in the host.

            None of the mappings may overlap.

            Use `userMaps` to control user mappings. Use `groupMaps` to control group mappings. The format is the same for both options.
          '';
          example = [
            "0:0:1"
            "1000:1000:1"
          ];
        };
        isolate = mkOption {
          default = true;
          type = types.bool;
          description = "Isolate this resource in the container.";
        };
      in
      {
        options = {
          users = mkOption {
            default = { };
            type = types.submodule (
              { ... }:
              {
                options = {
                  inherit isolate;
                  mapUsers = uid-gid-mapping;
                  mapGroups = uid-gid-mapping;
                };
              }
            );
            description = "Isolate users and groups in the container from the host.";
          };
          fs = mkOption {
            default = { };
            type = types.submodule (
              { ... }:
              {
                options = {
                  inherit isolate;
                  containerMounts = mkOption {
                    default = { };
                    type = types.attrsOf (
                      types.submodule (
                        { ... }:
                        {
                          options = {
                            hostPath = mkOption {
                              type = types.path;
                              description = "The path on the host that should be mounted inside the container.";
                            };
                            containerPath = mkOption {
                              type = types.path;
                              description = "The path in the container that the host path should be mounted to.";
                            };
                            readonly = mkOption {
                              default = false;
                              type = types.bool;
                              description = "When enabled, the mount cannot be written to from inside the container, regardless of permissions.";
                            };
                            mapPermissions = mkOption {
                              default = "container";
                              type = types.enum [
                                null
                                "container"
                                (types.submodule (
                                  { ... }:
                                  {
                                    options = {
                                      mapUsers = uid-gid-mapping;
                                      mapGroups = uid-gid-mapping;
                                    };
                                  }
                                ))
                              ];
                              description = ''
                                Configure how permissions are mapped for this specific mount in the container. Available options:

                                - `null`: Permissions are not mapped and use the exact same permissions as the host.
                                - `"container"`: The folder is mapped using the container's normal permission mappings (as defined in `isolation.users`). This option only applies if users are isolated in the container; e.g. it acts the same as `null` if `isolate.users.isolate` is `false`.
                                - `{ mapUsers = ...; mapGroups = ...; }`: Set your custom user/group mappings for this specific folder in the container (other folders are not affected, nor is the host/original folder). Mappings are specified the same way as `isolation.users`.
                              '';
                            };
                          };
                        }
                      )
                    );
                    description = "Mount folders from the host into the container.";
                  };
                };
              }
            );
            description = "Isolate the container and host filesystems.";
          };
          hostname = mkOption {
            default = name;
            type = types.nullOr types.str;
            description = ''
              If set, the container will use the given hostname (and therefore will have an isolated hostname). If `null`, the container will use the host's hostname (and therefore won't be isolated).
            '';
            example = null;
          };
          processes = mkOption {
            default = { };
            type = types.submodule (
              { ... }:
              {
                options = {
                  inherit isolate;
                  isolateIPC = mkOption {
                    default = true;
                    type = types.bool;
                    description = "Isolate IPC communication between processes in the container and host.";
                  };
                };
              }
            );
            description = "Isolate processes in the container from processes in the host.";
          };
          net = mkOption {
            default = { };
            type = types.submodule (
              { ... }:
              {
                options = { inherit isolate; };
              }
            );
            description = "Isolate the container's networking stack from the host's networking stack.";
          };
        };
      }
    );
    description = ''
      Uses Linux namespaces to isolate various software resources (filesystems, networks, users, etc.) between the container and host.

      Generally speaking all options in this module have two settings:
      - `isolate`: When enabled, the container will have its own version of the resource (i.e. its own users, filesystem, or network stack). When disabled, the container will use the same resource as the host. Enabled by default.
      - `map`: Allows you to "map" isolated container resources to host resources, and create exceptions to the container's isolation. For example, `users.map` lets you share the specified users between the container and host.
    '';
  };
  # TODO resource limits via cgroups
  # resourceLimits = mkOption {
  #   default = { };
  #   type = types.submodule ({ ... }: { });
  #   description = "Allows setting hard limits on how much of various hardware resources this container can use, e.g. 2G of RAM or 20% of the CPU. This is implemented via Linux cgroups.";
  # };

  config = mkOption {
    type = types.attrTag {
      flake = mkOption {
        type = types.anything; # TODO figure out what types flake refs can be
        description = "The Nix flake to build and use as the container's NixOS configuration. This must be a flake reference.";
      };
      module = mkOption {
        default = { };
        type = types.submodule (
          { config, ... }:
          {
            options = {
              nixpkgs = mkOption {
                default = pkgs;
                type = types.pkgs;
                description = "The Nixpkgs library to use to provide packages and NixOS settings in the container.";
              };
              specialArgs = mkOption {
                default = { };
                type = types.attrsOf types.anything;
                description = "Extra arguments to pass to the Nix Module.";
              };
              config = mkOption {
                type = lib.mkOptionType {
                  name = "Toplevel NixOS config";
                  merge =
                    loc: defs:
                    (import "${toString config.nixpkgs.path}/nixos/lib/eval-config.nix" {
                      inherit (config) specialArgs;

                      system = null;
                      modules = [
                        {
                          nixpkgs.hostPlatform = pkgs.stdenv.hostPlatform;
                          boot.isContainer = true;
                          networking.useDHCP = false;
                        }
                      ]
                      ++ (map (def: def.value) defs);
                    }).config;
                };
                description = "The actual NixOS configuration.";
              };
            };
          }
        );
      };
    };
    description = "The NixOS configuration for the container. You can specify either a Flake or a Nix Module to use as the configuration. To use a flake, see `config.flake`. To use a Nix Module, see `config.module`.";
  };
}
