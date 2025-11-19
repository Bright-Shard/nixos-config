final: prev:

let
  pkgs = final;
  inherit (pkgs) lib;
in
{
  # nixpkgs can be out-of-date...
  proton-ge-bin = prev.proton-ge-bin.overrideAttrs (old: rec {
    version = "GE-Proton10-25";
    src = prev.fetchzip {
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
      hash = "sha256-RKko4QMxtnuC1SAHTSEQGBzVyl3ywnirFSYJ1WKSY0k=";
    };
  });

  # p2pool isn't packaged at all, and the repo itself only provides a flake
  # This derivation is basically just copy/pasted from that flake
  p2pool = pkgs.stdenv.mkDerivation {
    pname = "p2pool";
    version = "0.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "SChernykh";
      repo = "p2pool";
      rev = "v4.12";
      hash = "sha256-Yrc36tibHanXZcE3I+xcmkCzBALE09zi1Zg0Lz3qS2g=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = builtins.attrValues {
      inherit (pkgs) cmake pkg-config;
    };

    buildInputs = builtins.attrValues {
      inherit (pkgs)
        libuv
        zeromq
        libsodium
        gss
        curl
        ;
    };

    cmakeFlags = [ "-DWITH_LTO=OFF" ];

    installPhase = ''
      mkdir -p $out/bin
      cp -r ./p2pool $out/bin/
    '';
  };

  # Compat for flakes
  legacyPackages = lib.genAttrs lib.systems.flakeExposed (system: pkgs);
}
