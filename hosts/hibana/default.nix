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
    networking.networkmanager.wifi.backend = "iwd";
    bs = {
      gui = true;
      syncthingId = "S2FBSZJ-5JQ5Y3W-DYMYI6G-AOUUIFE-M7BZUJ2-DK5R4GG-CXZWDGK-LEQKYQK";
      mullvad = true;
      mod = "Shift+Ctrl+Alt+Super";
      altMod = "Shift+Ctrl+Alt";
      firewall.openInterfacePorts.tailscale0.tcp = [
        11434 # ollama
      ];
      state-version = "25.11";
    };

    services = {
      ollama = {
        enable = false;
        package = pkgs.ollama-rocm;
        user = "ollama";
        group = "ollama";
        host = "0.0.0.0";
      };
      xmrig = {
        enable = false;
        settings = {
          autosave = false;
          cpu = {
            enabled = true;
            asm = "ryzen";
            max-threads-hint = 80;
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

    # Allow IP forwarding so this computer can be used as a TailScale exit node
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      # "net.ipv6.conf.all.forwarding" = 1;
    };
  };
}
