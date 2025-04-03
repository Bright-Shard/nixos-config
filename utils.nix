{ lib, HOSTNAME, ... }@inputs:

{
  hostname = HOSTNAME;

  # Font settings
  codeFont = "ShureTechMono Nerd Font";
  codeFontSize = 18;

  # Public keys
  pgpKey = ''
    -----BEGIN PGP PUBLIC KEY BLOCK-----

    mDMEZifSfxYJKwYBBAHaRw8BAQdASlxw0OM7dEjqzAERkJP5nIYM3XSOSabet7/U
    9wmqCQu0KUJyaWdodFNoYXJkIDxicmlnaHRzaGFyZEBicmlnaHRzaGFyZC5kZXY+
    iJMEExYKADsWIQToeVhSRVc3z/wDPOrcLK+wpsM2MAUCZifSfwIbIwULCQgHAgIi
    AgYVCgkICwIEFgIDAQIeBwIXgAAKCRDcLK+wpsM2MBXPAP9v0pHbWpxyItf2usbU
    aPWlHnPLn2luLW1L+hiUVQe4uAEAvhILeXFxfbfeIa+FbaP64zdD7RJPv2Yp8nF6
    9FycngC4OARmJ9LFEgorBgEEAZdVAQUBAQdA22y9EW2k74nVb6oBYEfZ92R7oysR
    dD6mdb9B4FXqrEkDAQgHiHgEGBYKACAWIQToeVhSRVc3z/wDPOrcLK+wpsM2MAUC
    ZifSxQIbDAAKCRDcLK+wpsM2MBhQAP9JZUlhQS10JT8Au5OOwYfG3xy1yIUWD1NQ
    65gCV0OU3wEAl12c8eyHbikNQpa1KpE4bALqYcMONkEgParBQz5hgwc==hJcS

    -----END PGP PUBLIC KEY BLOCK-----
  '';
  pgpKeyGpgId = "0xDC2CAFB0A6C33630";
  sshKey = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpccNDjO3RI6swBEZCT+ZyGDN10jkmm3re/1PcJqgkL
  '';
  sshKeyGpgId = "0xA79C716EC11610D2";

  # Attribute set of { hostName = module; } - allows accessing the modules of
  # all hosts, not just the current one
  hosts =
    with builtins;
    with lib;
    (
      let
        hosts = attrNames (readDir ./hosts);
        hostNameToModule =
          hostName:
          (evalModules {
            modules = [
              {
                options = {
                  hostOptions = import ./hostOptions.nix lib;
                };
              }

              ./hosts/${hostName}
            ] ++ import <nixpkgs/nixos/modules/module-list.nix>;
            specialArgs = inputs;
          }).config;
      in
      (listToAttrs (
        map (hostName: {
          name = hostName;
          value = hostNameToModule hostName;
        }) hosts
      ))
    );
}
