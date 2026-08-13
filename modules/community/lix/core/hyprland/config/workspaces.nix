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

        # Semantic workspaces (Prime-style): Mod+1/2/3 are fixed categories
        # (editors/media/terminal), the rest stay numbered. Apps are
        # auto-routed by window rules. Using PLAIN numbered workspaces (not
        # `name:`-named) so the bar shows 1/2/3 — named workspaces get
        # auto-allocated ids (e.g. 6) which displayed instead of the name.
        semantic = {
          "1" = "editors";
          "2" = "media";
          "3" = "terminal";
        };
        semanticBinds = lib.mapAttrsToList (key: _:
          (bind "${mainMod} + ${key}" (lua "hl.dsp.focus({ workspace = ${toString (lib.toInt key)} })")
            "Focus workspace ${toString (lib.toInt key)}")) semantic;
        semanticMoveBinds = lib.mapAttrsToList (key: _:
          (bind "${mainMod} + SHIFT + ${key}" (lua "hl.dsp.window.move({ workspace = ${toString (lib.toInt key)} })")
            "Move window to workspace ${toString (lib.toInt key)}")) semantic;

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

        # Auto-routing: window class -> workspace id (Prime muscle memory).
        # Hyprland 0.55+ Lua config: window rules are `hl.window_rule({...})`
        # calls; the home-manager `settings.window_rule` key does NOT render
        # (attrsOf drops it), so emit via extraConfig (raw Lua, verbatim).
        windowRuleLua = lib.concatStringsSep "\n" (
          map (rule: "hl.window_rule(${rule})") [
            # editors: emacs, neovim, thunar (files), obsidian (notes) -> ws 1
            "{ match = { class = '(^emacs)' }, workspace = 1 }"
            "{ match = { class = '(^nvim)' }, workspace = 1 }"
            "{ match = { class = '(^thunar)' }, workspace = 1 }"
            "{ match = { class = '(^obsidian)' }, workspace = 1 }"
            # media/browser: zen, mpv -> ws 2
            "{ match = { class = '(^zen)' }, workspace = 2 }"
            "{ match = { class = '(^mpv)' }, workspace = 2 }"
            # terminal/ai/research: ghostty -> ws 3
            "{ match = { class = '(^ghostty)' }, workspace = 3 }"
          ]
        );
      in
      {
        wayland.windowManager.hyprland = {
          settings = {
            bind = semanticBinds ++ semanticMoveBinds ++ workspaceBinds ++ relativeBinds;
          };
          extraConfig = windowRuleLua;
        };
      };
  };
}
