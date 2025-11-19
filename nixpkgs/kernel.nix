# Custom packaging for the Linux Hardened kernel, which is out-of-date in
# nixpkgs
# My Framework Desktop really needs as new a kernel as possible for the iGPU
# driver, but I don't really wanna stop using hardened, so here we are
{ pkgs, fetchurl, ... }:

let
  VERSION = {
    MAJOR = "6";
    MINOR = "17";
    PATCH = "8";
  };
  HARDENED-VER = 2;
  HARDENED-SHA256 = "sha256-Hk3/uhMY9DbSaMOaAvrFe2QwXkp+TOYQe1lPRtlqaF4=";
  KERNEL-SHA256 = "sha256-Wo3mSnX8pwbAHGwKd891p0YYQ52xleJfHwJor2svsdo=";

  version = with VERSION; "${MAJOR}.${MINOR}.${PATCH}";
  kernel = pkgs.${"linux_${VERSION.MAJOR}_${VERSION.MINOR}"};
  hardenedName = "linux-hardened-v${version}-hardened${toString HARDENED-VER}";
in

pkgs.linuxPackagesFor (
  kernel.override {
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/os-specific/linux/kernel/hardened/config.nix
    # It's out-of-date, I assume? I remove any attributes that cause compilation
    # errors.
    structuredExtraConfig = removeAttrs (import
      "${pkgs.path}/pkgs/os-specific/linux/kernel/hardened/config.nix"
      {
        inherit (pkgs) stdenv lib;
        inherit version;
      }
    ) [ "GCC_PLUGIN_STACKLEAK" ];
    argsOverride = {
      pname = "linux-hardened";
      inherit version;
      modDirVersion = "${version}-hardened${toString HARDENED-VER}";
      src = fetchurl {
        url = "mirror://kernel/linux/kernel/v${VERSION.MAJOR}.x/linux-${version}.tar.xz";
        sha256 = KERNEL-SHA256;
      };
      kernelPatches = kernel.kernelPatches ++ [
        {
          name = hardenedName;
          patch = fetchurl {
            url = "https://github.com/anthraxx/linux-hardened/releases/download/v${version}-hardened${toString HARDENED-VER}/${hardenedName}.patch";
            sha256 = HARDENED-SHA256;
          };
          extra = "-hardened${toString HARDENED-VER}";
          inherit version;
          sha256 = HARDENED-SHA256;
        }
      ];
      isHardened = true;
    };
  }
)
