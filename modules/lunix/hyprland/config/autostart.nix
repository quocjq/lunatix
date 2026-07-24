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
                  -- fcitx5 daemon (lotus engine is auto-added as addon).
                  -- Use the system wrapper so the addons resolved by
                  -- `i18n.inputMethod.fcitx5.addons` are visible.
                  hl.exec_cmd("/run/current-system/sw/bin/fcitx5 -d")
                end
              '')
            ];
          };
        };
      };
    };
}
