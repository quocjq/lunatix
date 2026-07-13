{
  lix.hyprland = { ... }: {
    homeManager =
      { lib, ... }:
      let
        lua = lib.generators.mkLuaInline;
        mainMod = "SUPER";
        bind = keys: dispatcher: desc: {
          _args = [
            keys
            dispatcher
            { description = desc; }
          ];
        };
        workspaceBinds = lib.concatLists (
          builtins.genList (
            i:
            let
              ws = i + 1;
              key = if ws == 10 then "0" else toString ws;
            in
            [
              (bind "${mainMod} + ${key}" (lua "hl.dsp.focus({ workspace = ${toString ws} })")
                "Focus workspace ${toString ws}"
              )

              (bind "${mainMod} + SHIFT + ${key}" (lua "hl.dsp.window.move({ workspace = ${toString ws} })")
                "Move window to workspace ${toString ws}"
              )
            ]
          ) 10
        );
        relativeBinds = [
          (bind "${mainMod} + Prior" (lua ''hl.dsp.focus({ workspace = "r-1" })'') "Focus previous workspace")
          (bind "${mainMod} + Next" (lua ''hl.dsp.focus({ workspace = "r+1" })'') "Focus next workspace")
        ];
      in
      {
        wayland.windowManager.hyprland.settings = {
          bind = workspaceBinds ++ relativeBinds;
        };
      };
  };
}
