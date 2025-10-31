{
  enable = true;
  systemd.enable = true;
  style = ''
    window#waybar {
      background-color: rgba(0, 0, 0, 0);
      color: @text;
    }
    .modules-left, .modules-center, .modules-right {
      background-color: @crust;
      border-radius: 12px;
      padding: 5px;
      margin-top: 6px;
    }
    .modules-left {
      margin-left: 12px;
    }
    .modules-right {
      margin-right: 12px;
    }

    .module {
      margin: 0px 7px;
    }

    #cava {
      margin-left: 30px;
    }
  '';
  settings = {
    bar = {
      layer = "top";
      position = "top";

      modules-left = [
        "clock"
        "custom/date"
        "cava"
        "mpris"
      ];
      modules-center = [ "niri/window" ];
      modules-right = [
        "cpu"
        "memory"
      ];

      "custom/date" = {
        exec = "date +'%a, %b %d'";
        format = "{}";
        interval = 60;
      };

      cpu = {
        format = "  {}%";
        interval = 1;
      };
      memory = {
        format = "  {}%";
        interval = 1;
      };

      cava = {
        framerate = 60;
        autosens = 1;
        bars = 14;
        sample_rate = 44100;
        sample_bits = 16;
        lower_cutoff_freq = 50;
        higher_cutoff_freq = 10000;
        hide_on_silence = false;
        method = "pipewire";
        source = "auto";
        stereo = true;
        reverse = false;
        bar_delimiter = 0;
        monstercat = false;
        waves = false;
        noise_reduction = 0.5;
        format-icons = [
          "▁"
          "▂"
          "▃"
          "▄"
          "▅"
          "▆"
          "▇"
          "█"
        ];
        actions.on-click = "mode";
      };
      mpris = {
        format = "󰝚  {artist} - {title}";
        format-paused = "󰝛  {artist} - {title}";
      };
    };
  };
}
