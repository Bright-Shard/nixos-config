final: prev:

{
  # nixpkgs can be out-of-date...
  proton-ge-bin = prev.proton-ge-bin.overrideAttrs (old: rec {
    version = "GE-Proton10-24";
    src = prev.fetchzip {
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${version}/${version}.tar.gz";
      hash = "sha256-sJkaDEnfAuEqcLDBtAfU6Rny3P3lOCnG1DusWfvv2Fg=";
    };
  });
}
