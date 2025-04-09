{ pkgs, ... }:

let
  toml = pkgs.formats.toml { };
in
{
  home.packages = with pkgs; [ halloy ];
  xdg.configFile."halloy/config.toml".text = builtins.readFile (
    toml.generate "halloy.toml" {
      theme = "Catppuccin Mocha";
      servers = {
        hackint = {
          nickname = "brightshard";
          server = "irc.hackint.org";
          channels = [
            "#hackint"
            "#tvl"
          ];
          chathistory = true;
        };
        libera = {
          nickname = "brightshard";
          server = "irc.libera.chat";
          port = 6697;
          channels = [ "#halloy" ];
        };
      };
    }
  );
}
