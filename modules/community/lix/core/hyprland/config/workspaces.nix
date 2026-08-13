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

        # Semantic workspaces (Prime-style): Mod+1/2/3 are fixed categories,
        # the rest stay numbered. Apps are auto-routed by windowrule so each
        # Mod+N is deterministic.
        named = {
          "1" = "editors";
          "2" = "media";
          "3" = "terminal";
        };
        namedBinds = lib.mapAttrsToList (key: name:
          (bind "${mainMod} + ${key}" (lua "hl.dsp.focus({ workspace = '${name}' })")
            "Focus workspace ${name}")) named;
        namedMoveBinds = lib.mapAttrsToList (key: name:
          (bind "${mainMod} + SHIFT + ${key}" (lua "hl.dsp.window.move({ workspace = '${name}' })")
            "Move window to workspace ${name}")) named;

        # Numbered workspaces 4..10 (0 = 10)
        numbered = builtins.genList (i: i + 4) 7;
        workspaceBinds = lib.concatLists (
          builtins.map (i:
            let
              ws = i;
              key = if ws == 10 then "0" else toString ws;
            in
            [
              (bind "${mainMod} + ${key}" (lua "hl.dsp.focus({ workspace = ${toString ws} })")
                "Focus workspace ${toString ws}"
              )
              (bind "${mainMod} + SHIFT + ${key}" (lua "hl.dsp.window.move({ workspace = ${toString ws} })")
                "Move window to workspace ${toString ws}"
              )
            ]) numbered
        );
        relativeBinds = [
          (bind "${mainMod} + Prior" (lua ''hl.dsp.focus({ workspace = "r-1" })'') "Focus previous workspace")
          (bind "${mainMod} + Next" (lua ''hl.dsp.focus({ workspace = "r+1" })'') "Focus next workspace")
        ];

        # Auto-routing: window class -> semantic workspace (Prime muscle memory).
        windowRules = [
          # editors: emacs, neovim, thunar (files), obsidian (notes)
          { _args = [ "workspace name:editors,class:emacs" ]; }
          { _args = [ "workspace name:editors,class:(^nvim)" ]; }
          { _args = [ "workspace name:editors,class:(^thunar)" ]; }
          { _args = [ "workspace name:editors,class:(^obsidian)" ]; }
          # media/browser
          { _args = [ "workspace name:media,class:(^zen)" ]; }
          { _args = [ "workspace name:media,class:(^mpv)" ]; }
          # terminal/ai/research
          { _args = [ "workspace name:terminal,class:(^ghostty)" ]; }
        ];
      in
      {
        wayland.windowManager.hyprland.settings = {
          bind = namedBinds ++ namedMoveBinds ++ workspaceBinds ++ relativeBinds;
          windowrule = windowRules;
        };
      };
  };
}
