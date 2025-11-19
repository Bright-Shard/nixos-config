with builtins;

{
  # NixOS wireguard interface configuration
  HOPPY = import ./hoppy.nix;
  # Settings for monero etc.
  CRYPTO = import ./crypto.nix;
  KAGI-TOKEN = readFile ./kagi-token.txt;
}
