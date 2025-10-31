{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    # putting the vi(m) in nvim
    vimAlias = true;
    viAlias = true;

    configure = {
      customLuaRC = ''
        -- todo lmao
      '';
      packages.bs_init.start = with pkgs.vimPlugins; [
        astrocore
        astroui
        astrolsp
        astrotheme
      ];
    };
  };
}
