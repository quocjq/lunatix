{ lib, ... }:
let
  monitorType = lib.types.submodule {
    options = {
      output = lib.mkOption {
        type = lib.types.str;
        description = "Display output name (e.g. DP-1, HDMI-A-1)";
      };
      mode = lib.mkOption {
        type = lib.types.str;
        description = "Resolution and refresh rate (e.g. 2560x1440@144)";
      };
      position = lib.mkOption {
        type = lib.types.str;
        default = "0 0";
        description = "Monitor position";
      };
      scale = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
        description = "Scale factor";
      };
      wpeng = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Wallpaper engine wallpaper ID";
      };
    };
  };
in
{
  lix.hyprland.provides.to-hosts.nixos =
    { lib, ... }:
    {
      options.aquaticConfig.hyprland.monitors = lib.mkOption {
        type = lib.types.listOf monitorType;
        default = [ ];
      };
    };

  flake.modules.homeManager.hyprland =
    { nixosConfig, ... }:
    {
      config.wayland.windowManager.hyprland.settings.monitor = lib.map (mon: {
        output = mon.output;
        mode = mon.mode;
        position = mon.position;
        scale = mon.scale;
      }) nixosConfig.aquaticConfig.hyprland.monitors;
    };
}
