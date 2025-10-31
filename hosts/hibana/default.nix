{
  NPINS,
  pkgs,
  crux,
  ...
}:

with crux;

{
  imports = [ "${NPINS.nixware}/framework/desktop/amd-ai-max-300-series" ];

  config = {
    bs = {
      gui = true;
      syncthingId = "S2FBSZJ-5JQ5Y3W-DYMYI6G-AOUUIFE-M7BZUJ2-DK5R4GG-CXZWDGK-LEQKYQK";
      mullvad = true;
      mod = "Shift+Ctrl+Alt+Super";
      altMod = "Shift+Ctrl+Alt";
      firewall.openInterfacePorts.tailscale0.tcp = [
        11434 # ollama
      ];
    };

    services = {
      ollama = {
        enable = true;
        acceleration = "rocm";
        openFirewall = true;
        user = "ollama";
        group = "ollama";
      };
      xmrig = {
        enable = true;
        settings = {
          autosave = false;
          cpu = {
            enabled = true;
            asm = "ryzen";
            max-threads-hint = 90;
          };
          opencl = {
            enabled = true;
            loader = "${pkgs.rocmPackages.clr}/lib/libOpenCL.so";
          };
          pools = [
            {
              coin = "monero";
              url = "brilliance.bs:3333";
            }
          ];
        };
      };
    };

    # This option defines the first version of NixOS you have installed on this particular machine,
    # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
    #
    # Most users should NEVER change this value after the initial install, for any reason,
    # even if you've upgraded your system to a new NixOS release.
    #
    # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
    # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
    # to actually do that.
    #
    # This value being lower than the current NixOS release does NOT mean your system is
    # out of date, out of support, or vulnerable.
    #
    # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
    # and migrated your data accordingly.
    #
    # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
    system.stateVersion = "25.11"; # Did you read the comment?
  };
}
