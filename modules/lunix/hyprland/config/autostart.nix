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
                  hl.exec_cmd("bluetooth")
                  hl.exec_cmd("noctalia")
                  hl.exec_cmd("emacs")
                end
              '')
            ];
          };
        };
      };
    };
}
