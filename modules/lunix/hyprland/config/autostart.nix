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
                  hl.exec_cmd("emacsclient -c -e \\\"(eshell)\\\" ")
                  hl.exec_cmd("bluetooth")
                  hl.exec_cmd("noctalia")
                end
              '')
            ];
          };
        };
      };
    };
}
