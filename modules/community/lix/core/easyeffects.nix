{ __findFile, ... }: {
  lix.easyeffects = {
    os = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.easyeffects ];
    };
    maid = {
      # Presets mirror the old home-manager `services.easyeffects`
      # declaration (`preset = "default"`, input rnnoise). The HM systemd
      # daemon/autostart is dropped with the migration; the GUI runs on demand.
      file.xdg_config."easyeffects/input/default.json".text = ''
        {
          "blocklist": [],
          "plugins_order": ["rnnoise#0"],
          "rnnoise#0": {
            "bypass": false,
            "enable-vad": false,
            "input-gain": 0.0,
            "model-path": "",
            "output-gain": 0.0,
            "release": 20.0,
            "vad-thres": 50.0,
            "wet": 0.0
          }
        }
      '';
      file.xdg_config."easyeffects/output/default.json".text = "{}";
    };
  };
}