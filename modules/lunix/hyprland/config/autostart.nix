{ ... }:
{
  lix.hyprland.homeManager =
    { lib, ... }:
    let
      lua = lib.generators.mkLuaInline;
    in
    {
      wayland.windowManager.hyprland = {
        settings = {
          on = {
            _args = [
              "hyprland.start"
              (lua ''
                function()
                  hl.exec_cmd("emacs")
                  hl.exec_cmd("zen-twilight")
                end
              '')
            ];
          };
        };
      };
    };
}
