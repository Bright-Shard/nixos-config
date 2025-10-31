{
  crux,
  config,
  pkgs,
  lib,
  ...
}:

with crux;
let
  containers = config.bs.containers;
  containerNames = attrNames containers;
in

{
  systemd.targets.containers = {
    wantedBy = [ "multi-user.target" ];
    wants = map (containerName: "container@${containerName}.service") (
      filter (containerName: containers.${containerName}.autoStart) (attrNames containers)
    );
  };

  systemd = {
    services = listToAttrs (
      map (
        containerName:
        let
          # Container info
          container = containers.${containerName};
          inherit (container) isolation;
          containerDir = "/cnt/containers/${containerName}";
          containerDirRoot = "${containerDir}/root";
          containerDirNamespaces = "${containerDir}/namespaces";
          containerNixConfig =
            let
              cnt = containers.${containerName};
            in
            if cnt.config ? flake then
              (getFlake cnt.config.flake).nixosConfigurations.${containerName}
            else
              cnt.config.module.config.system.build.toplevel;

          # Utils
          ifStr = flag: str: if flag then str else "";
          namespace = ns: "${containerDirNamespaces}/${ns}";

          # List of Linux kernel namespaces that this container needs for proper
          # resource isolation.
          namespaces =
            let
              mk = flag: name: if flag then [ name ] else [ ];
            in
            (mk isolation.process.isolateIPC "ipc")
            ++ (mk (isolation.fs.isolate || isolation.users.isolate) "mount")
            ++ (mk isolation.net.isolate "net")
            ++ (mk isolation.process.isolate "pid")
            ++ (mk (isolation.hostname != null) "uts")
            ++ (mk isolation.users.isolate "user");
        in
        {
          name = "container@${containerName}";
          value = {
            script = ''
              PATH=${pkgs.util-linux}/bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin

              # Remove old namespaces if present (e.g. when restarting the
              # container)
              if [ -e ${containerDirNamespaces} ]; then
              	umount -R ${containerDirNamespaces} | true
               	rm -rf ${containerDirNamespaces}
              fi

              # Ensure the container directories exist
              mkdir -p ${containerDirNamespaces} \
                /nix/var/nix/profiles/per-container/${containerName} \
                /nix/var/nix/gcroots/per-container/${containerName}

              # Small communication socket that lets this setup script set up
              # things after the container's namespaces have been made but
              # before the container actually boots
              if [ -e ${containerDir}/setup.sock ]; then
                # If a previous attempt to start the container failed partway
                # this file may be leftover
              	rm ${containerDir}/setup.sock
              fi
              mkfifo --mode=777 ${containerDir}/setup.sock

              # Prepare the "namespaces" directory - a tmpfs private to the
              # host's mount namespace
              # We can't bind namespaces to files in public mounts, so we make
              # this private
              mount --make-private -t tmpfs tmpfs ${containerDirNamespaces}

              # Create all the files to bind namespaces to
              touch ${concatStringsSep " " (map (ns: namespace ns) namespaces)}

              # Start a background task to setup the container's filesystem
              coproc bash -e << 'EOF1'
                echo "sleeping"
                # Wait for the container to boot (so we know all the namespaces
                # have been made)
                read < ${containerDir}/setup.sock
                echo "container booted"

                # Setup the container's filesystem (if needed)
                ${
                  let
                    userns = ifStr isolation.users.isolate "nsenter --user=${namespace "user"} --setuid=0 --setgid=0";
                  in
                  ifStr isolation.fs.isolate ''
                    # First we make a folder to represent the container's root
                    # filesystem, and mount any folders that are shared with the
                    # host under that folder.
                    # We do all of this outside of the container's namespaces so
                    # we still have permissions on the host to access all the
                    # folders that need sharing. If we, for example, tried to
                    # mount host folders into the container's root filesystem
                    # from within the container's user namespace, the kernel
                    # would see us as a different user that lacks permissions
                    # to read/mount those folders.
                    mkdir -p ${containerDirRoot}

                    # Make the root folder a mount point. This is needed so the
                    # container can set this folder as the root folder, and so
                    # we can map the folder to the container's user namespace
                    # (if it has one).
                    # We first unmount the root folder if it was already mounted
                    # (which may happen if the container's service is restarted
                    # ) to ensure that the folder is mounted with the up-to-date
                    # permissions & namespace.
                    set +e
                    mountpoint -q ${containerDirRoot}
                    if [ $? -eq 0 ]; then
                      set -e
                      umount -R ${containerDirRoot}
                    fi
                    set -e
                    mount --bind ${ifStr isolation.users.isolate "--map-users=${namespace "user"}"} ${containerDirRoot} ${containerDirRoot}

                    ${
                      let
                        mk = hostPath: containerPath: {
                          inherit hostPath containerPath;
                          readonly = false;
                          mapPermissions = "container";
                        };
                        mkR = path: {
                          hostPath = path;
                          containerPath = path;
                          readonly = true;
                          mapPermissions = "container";
                        };

                        # Nix-specific directories we need to share with the
                        # container
                        nixDirs = [
                          (mkR "/nix/store")
                          (mkR "/nix/var/nix/db")
                          (mkR "/nix/var/nix/daemon-socket")
                          (mk "/nix/var/nix/profiles/per-container/${containerName}" "/nix/var/nix/profiles")
                          (mk "/nix/var/nix/gcroots/per-container/${containerName}" "/nix/var/nix/gcroots")
                        ];
                        # Directories the user specified to share with the
                        # container
                        userDirs = attrValues isolation.fs.containerMounts;
                        # All the directories we need to mount
                        dirs = nixDirs ++ userDirs;
                      in

                      concatStringsSep "\n\n" (
                        map (
                          dir:
                          let
                            # Converts the container-relative path to an
                            # absolute path on the host, handling paths with or
                            # without a "/" prefix.
                            containerPath = "${containerDirRoot}/${lib.strings.removePrefix "/" dir.containerPath}";
                          in
                          ''
                            ${userns} mkdir -p ${containerPath}

                            mount --bind \
                              ${ifStr dir.readonly "-r"} \
                              ${
                                if dir.mapPermissions == "container" then
                                  ifStr isolation.users.isolate "--map-users=${namespace "user"}"
                                else if dir.mapPermissions != null then
                                  concatStringsSep " " [
                                    (concatStringsSep " " (map (mapping: "--map-users=${mapping}") dir.mapPermissions.mapUsers))
                                    (concatStringsSep " " (map (mapping: "--map-groups=${mapping}") dir.mapPermissions.mapGroups))
                                  ]
                                else
                                  ""
                              } \
                              ${dir.hostPath} ${containerPath}
                          ''
                        ) dirs
                      )
                    }
                  ''
                }

                # Tell the container to boot
                printf "\n" > ${containerDir}/setup.sock
                # Cleanup
                rm ${containerDir}/setup.sock
              EOF1

              # Start the container
              unshare \
                ${concatStringsSep " " (map (ns: "--${ns}=${namespace ns}") namespaces)} \
                ${ifStr isolation.users.isolate ''
                  ${concatStringsSep " " (map (mp: "--map-users=${mp}") isolation.users.mapUsers)} \
                  ${concatStringsSep " " (map (mp: "--map-groups=${mp}") isolation.users.mapGroups)} \
                  --setuid=0 --setgid=0 \
                ''} \
                ${ifStr isolation.process.isolate "--fork --kill-child"} \
                ${ifStr isolation.fs.isolate "--propagation slave"} \
                ${pkgs.bash}/bin/bash -e << 'EOF2'
                  # Notify the host that the container has started
                  printf "\n" > ${containerDir}/setup.sock
                	# Wait for the container setup script to do any additional
                  # setup before continuing
                  read < ${containerDir}/setup.sock

                  ${
                    if isolation.fs.isolate then
                      ''
                        # Stop receiving mount events from the host (to help
                        # with FS isolation)
                        mount --make-rprivate /

                        # Setup proc, dev, and sys filesystems
                        # Note that the dev and sys filesystems don't support
                        # namespaces. So we have to make our own psuedo-dev/sys
                        # filesystems for those directories.
                        mount --mkdir -t proc proc ${containerDirRoot}/proc
                        mount --mkdir -t tmpfs \
                          -o nosuid,strictatime,mode=0755,size=65536k \
                          tmpfs ${containerDirRoot}/dev
                        chroot ${containerDirRoot} mknod -m 666 /dev/null c 1 3
                        mknod -m 666 ${containerDirRoot}/dev/zero c 1 5
                        mknod -m 666 ${containerDirRoot}/dev/full c 1 7
                        mknod -m 666 ${containerDirRoot}/dev/random c 1 8
                        mknod -m 666 ${containerDirRoot}/dev/urandom c 1 9
                        mknod -m 666 ${containerDirRoot}/dev/tty c 1 0

                        # Set the root folder for the entire mount namespace
                        cd ${containerDirRoot}
                        mkdir .oldroot
                        pivot_root . .oldroot
                        exec chroot . ${pkgs.bash}/bin/bash -e << 'EOF3'
                          PATH=${pkgs.util-linux}/bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin
                          cd /
                          pwd
                          ls -al
                          echo $UID:$GID
                          whoami
                          # Unmount the old root
                          umount .oldroot
                          rm -rf .oldroot

                          # Boot
                          . ${containerNixConfig}/init
                        ${"\n"}EOF3
                      ''
                    else
                      ". ${containerNixConfig}/init"
                  }
                ${"\n"}EOF2

              wait
            '';
          };
        }
      ) containerNames
    );
  };
}
