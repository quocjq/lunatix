{ ... }:
{
  lix.hyprland.homeManager =
    { lib, ... }:
    {
      wayland.windowManager.hyprland = {
        settings = {
          config = {
            general = {
              gaps_in = 4;
              gaps_out = 10;
              border_size = 1;
              col = {
                active_border = lib.generators.mkLuaInline "colors.mauve";
                inactive_border = lib.generators.mkLuaInline "colors.overlay0";
              };
              layout = "dwindle";
              resize_on_border = true;
            };

            render = {
              # direct_scanout = 2;
            };

            misc = {
              focus_on_activate = true;

              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              # on_focus_under_fullscreen = 1;
            };
          };
        };
      };
    };
}
