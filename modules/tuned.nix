{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkOption;
  inherit (lib.types)
    bool
    int
    str
    nullOr
    enum
    oneOf
    separatedString
    package
    attrsOf
    anything
    ;
  inherit (pkgs) callPackage;
  inherit (builtins)
    readDir
    listToAttrs
    toString
    filter
    concatLists
    toPath
    attrNames
    unsafeDiscardStringContext
    ;
  cfg = config.services.tuned;
  stringList = oneOf [
    (separatedString ",")
    (separatedString ";")
  ];
  iniGlobalFormat = pkgs.formats.iniWithGlobalSection { };
  iniFormat = pkgs.formats.ini { };
  genEtcFolder =
    prefix: src:
    let
      dir = toPath src;
      # path -> [set]
      handleFiles =
        dir:
        let
          contents = readDir dir;
          dirName = baseNameOf dir;
        in
        # Safety: This derivation is the same one that the tuned bins exist in.
        # So if the service is enabled, the bins are used and this derivation is used.
        # Therefore it's safe to refer to this derivation.
        # https://discourse.nixos.org/t/not-allowed-to-refer-to-a-store-path-error/5226/4
        map (file: {
          name = "${unsafeDiscardStringContext dirName}/${toString file}";
          value = {
            source = builtins.storePath (toPath "${dir}/${file}");
          };
        }) (filter (item: contents.${item} != "directory") (attrNames contents));
      # path -> [[set]]
      handleSubdirs =
        dir:
        let
          contents = readDir dir;
        in
        map (folder: handleDir (toPath "${dir}/${folder}")) (
          filter (item: contents.${item} == "directory") (attrNames contents)
        );
      handleDir =
        dir:
        let
          dirName = unsafeDiscardStringContext (baseNameOf dir);
        in
        (handleFiles dir)
        ++ (map (val: {
          name = "${dirName}/${val.name}";
          value = val.value;
        }) (concatLists (handleSubdirs dir)));
    in
    listToAttrs (
      map (val: {
        name = "${prefix}${val.name}";
        value = val.value;
      }) (handleDir dir)
    );
in
{
  options = {
    services.tuned = {
      package = mkOption {
        description = "The TuneD package to install.";
        type = package;
        default = callPackage ./tuned.pkg.nix { };
      };
      enable = mkOption {
        description = "Whether to enable TuneD.";
        type = bool;
        default = false;
      };
      profiles = mkOption {
        description = "Custom TuneD profiles.";
        type = attrsOf anything;
        default = { };
      };
      globalSettings = {
        daemon = mkOption {
          type = bool;
          default = true;
        };
        dynamic_tuning = mkOption {
          type = bool;
          default = false;
        };
        sleep_interval = mkOption {
          type = int;
          default = 1;
        };
        update_interval = mkOption {
          type = int;
          default = 10;
        };
        recommend_command = mkOption {
          type = bool;
          default = true;
        };
        reapply_sysctl = mkOption {
          type = bool;
          default = true;
        };
        default_instance_priority = mkOption {
          type = int;
          default = 0;
        };
        udev_buffer_size = mkOption {
          type = str;
          default = "1MB";
        };
        log_file_count = mkOption {
          type = int;
          default = 2;
        };
        log_file_max_size = mkOption {
          type = str;
          default = "1MB";
        };
        uname_string = mkOption {
          type = nullOr str;
          default = null;
        };
        cpuinfo_string = mkOption {
          type = nullOr str;
          default = null;
        };
        enable_dbus = mkOption {
          type = bool;
          default = true;
        };
        enable_unix_socket = mkOption {
          type = bool;
          default = false;
        };
        unix_socket_path = mkOption {
          type = str;
          default = "/run/tuned/tuned.sock";
        };
        unix_socket_signal_paths = mkOption {
          type = stringList;
          default = "";
        };
        unix_socket_ownership = mkOption {
          type = str;
          default = "-1 -1";
        };
        unix_socket_permissions = mkOption {
          type = str;
          default = "0o600";
        };
        connections_backlog = mkOption {
          type = int;
          default = 1024;
        };
        rollback = mkOption {
          type = enum [
            "auto"
            "not_on_exit"
          ];
          default = "auto";
        };
        profile_dirs = mkOption {
          type = stringList;
          default = "${cfg.package}/lib/tuned/profiles,/etc/tuned/profiles";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.tuned = {
      description = "Dynamic System Tuning Daemon";
      after = [
        "systemd-sysctl.service"
        "network.target"
        "dbus.service"
        "polkit.service"
      ];
      requires = [ "dbus.service" ];
      conflicts = [
        "cpupower.service"
        "auto-cpufreq.service"
        "tlp.service"
        "power-profiles-daemon.service"
      ];
      documentation = [
        "man:tuned(8)"
        "man:tuned.conf(5)"
        "man:tuned-adm(8)"
      ];
      serviceConfig = {
        Type = "dbus";
        PIDFile = "/run/tuned/tuned.pid";
        BusName = "com.redhat.tuned";
        ExecStart = "${cfg.package}/bin/tuned -l -P";
      };
      wantedBy = [ "multi-user.target" ];
    };
    environment.etc =
      (genEtcFolder "" "${cfg.package}/etc/tuned")
      // (genEtcFolder "tuned/" "${cfg.package}/lib/tuned/recommend.d")
      // {
        "tuned/tuned-main.conf".source = iniGlobalFormat.generate "tuned-main.conf" {
          sections = { };
          globalSection = cfg.globalSettings;
        };
        # TuneD writes to these files to persist data; we shouldn't symlink them since that makes them read-only
        "tuned/active_profile".enable = false;
        "tuned/profile_mode".enable = false;
        "tuned/post_loaded_profile".enable = false;
      }
      // (listToAttrs (
        map (profile: {
          name = "tuned/profiles/${profile}/tuned.conf";
          value = {
            source = iniFormat.generate "tuned-profile-${profile}.conf" cfg.profiles.${profile};
          };
        }) (attrNames cfg.profiles)
      ));

    environment.systemPackages = [ cfg.package ];
    services.dbus.packages = [ cfg.package ];
  };
}
