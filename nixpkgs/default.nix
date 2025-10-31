final: prev:

let
  pkgs = final;
in
{
  # nixpkgs can be out-of-date...
  proton-ge-bin = prev.proton-ge-bin.overrideAttrs (old: rec {
    version = "GE-Proton10-24";
    src = prev.fetchzip {
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
      hash = "sha256-QZBu2C4JrsETY+EV0zs4e921qOxYT9lk0EYXXpOCKLs=";
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
      rev = "v4.11";
      hash = "sha256-qoz7wMI6hheF+Pecfq3pPZRc2H3nkrxKRMWR2qmJdsI=";
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
}
