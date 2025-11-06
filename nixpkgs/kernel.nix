# Custom packaging for the Linux Hardened kernel, which is out-of-date in
# nixpkgs
# My Framework Desktop really needs as new a kernel as possible for the iGPU
# driver, but I don't really wanna stop using hardened, so here we are
{ pkgs, fetchurl, ... }:

# Edit: Above used to be true. Nowadays I tend to run bleeding edge new Linux
# because I've run into odd bugs.
pkgs.linuxPackages_testing

# let
#   VERSION = {
#     MAJOR = "6";
#     MINOR = "16";
#     PATCH = "10";
#   };
#   HARDENED-SHA256 = "sha256-tNW3MIjOojaImFV7j67CgBmxVZogMRjrj2F29jvxcr0=";
#   KERNEL-SHA256 = "sha256-qwa7qIUeS2guiDT2+Q5W0y3PmNjGLNU3Z2EEz9dXqPI=";

#   version = with VERSION; "${MAJOR}.${MINOR}.${PATCH}";
#   kernel = pkgs.${"linux_${VERSION.MAJOR}_${VERSION.MINOR}"};
#   hardenedName = "linux-hardened-v${version}-hardened1";
# in

# pkgs.linuxPackagesFor (
#   kernel.override {
#     structuredExtraConfig = import "${pkgs.path}/pkgs/os-specific/linux/kernel/hardened/config.nix" {
#       inherit (pkgs) stdenv lib;
#       inherit version;
#     };
#     argsOverride = {
#       pname = "linux-hardened";
#       inherit version;
#       modDirVersion = "${version}-hardened1";
#       src = fetchurl {
#         url = "mirror://kernel/linux/kernel/v${VERSION.MAJOR}.x/linux-${version}.tar.xz";
#         sha256 = KERNEL-SHA256;
#       };
#       kernelPatches = kernel.kernelPatches ++ [
#         {
#           name = hardenedName;
#           patch = fetchurl {
#             url = "https://github.com/anthraxx/linux-hardened/releases/download/v${version}-hardened1/${hardenedName}.patch";
#             sha256 = HARDENED-SHA256;
#           };
#           extra = "-hardened1";
#           inherit version;
#           sha256 = HARDENED-SHA256;
#         }
#       ];
#       isHardened = true;
#     };
#   }
# )
