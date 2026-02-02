{ ... }:

{
  config = {
    home = {
      username = "guest";
      homeDirectory = "/home/guest";
    };

    programs = {
      home-manager.enable = true;
      zen-browser = {
        enable = true;
        profiles."default" = {
          spaces = {
            Default = {
              id = "00000000-0000-0000-0000-000000000001";
              position = 1;
              icon = "🌐";
            };
          };
        };
      };
    };
  };
}
