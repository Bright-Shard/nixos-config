{ stdenv }:
stdenv.mkDerivation {
  name = "Zen Browser 1Password Patch";
  version = "1.0.0";
  src = ./.;
  installPhase = ''
    mkdir -p $out/etc/1password
    echo ".zen-wrapped" > $out/etc/1password/custom_allowed_browsers
  '';
}
