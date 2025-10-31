# Downloads the leaked IDA 9.0 beta and patches it to give free access to IDA
# Pro.

{
  ida-free,
  fetchurl,
  python3,
}:

let
  uncracked = ida-free.overrideAttrs (old: {
    pname = "ida-pro";
    version = "9.0";

    src = fetchurl {
      url = "https://archive.org/download/ida90beta/idapro_90_x64linux.run";
      hash = "sha256-CxKnmPDiq3xbenlesnUTavf86INW/d79f3d2xqpYg3I=";
    };

    # Small patches on the IDA free installation script
    autoPatchelfIgnoreMissingDeps = old.autoPatchelfIgnoreMissingDeps ++ [
      "libQt5EglFSDeviceIntegration.so.5"
    ];
    installPhase = builtins.replaceStrings [ "$IDADIR/ida" ] [ "$IDADIR/ida64" ] old.installPhase;
  });
in

uncracked.overrideAttrs (old: {
  postInstall = ''
    cd $out/opt/${old.pname}-${old.version}

    ${python3}/bin/python3 << 'EOF'
    ${builtins.readFile ./ida.py}
    EOF

    mv libida.so.patched libida.so
    mv libida64.so.patched libida64.so
  '';
})
