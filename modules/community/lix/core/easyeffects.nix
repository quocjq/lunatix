{ __findFile, ... }: {
  lix.easyeffects = {
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        easyeffects
      ];
      services.easyeffects = {
        enable = true;
        preset = "default";
        extraPresets = {
          default = {
            input = {
              blocklist = [ ];
              "plugins_order" = [ "rnnoise#0" ];
              "rnnoise#0" = {
                bypass = false;
                "enable-vad" = false;
                "input-gain" = 0.0;
                "model-path" = "";
                "output-gain" = 0.0;
                release = 20.0;
                "vad-thres" = 50.0;
                wet = 0.0;
              };
            };
          };
        };
      };
    };
  };
}