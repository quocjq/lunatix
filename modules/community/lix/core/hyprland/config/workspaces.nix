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
        # the rest stay numbered. Apps are auto-routed by window rules so each
        # Mod+N is deterministic. Hyprland named-workspace selectors need the
        # `name:` prefix (bare "editors" is an invalid selector -> focus no-op).
        named = {
          "1" = "name:editors";
          "2" = "name:media";
          "3" = "name:terminal";
        };
        namedBinds = lib.mapAttrsToList (key: sel:
          (bind "${mainMod} + ${key}" (lua "hl.dsp.focus({ workspace = '${sel}' })")
            "Focus workspace ${sel}")) named;
        namedMoveBinds = lib.mapAttrsToList (key: sel:
          (bind "${mainMod} + SHIFT + ${key}" (lua "hl.dsp.window.move({ workspace = '${sel}' })")
            "Move window to workspace ${sel}")) named;

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
        # Hyprland 0.55+ Lua config: window rules are `hl.window_rule({...})`
        # calls. The home-manager `settings.window_rule` key does NOT render
        # (attrsOf drops it), so emit them via extraConfig (raw Lua, verbatim).
        # Named workspaces require the `name:` prefix in the rule value too.
        windowRuleLua = lib.concatStringsSep "\n" (
          map (rule: "hl.window_rule(${rule})") [
            # editors: emacs, neovim, thunar (files), obsidian (notes)
            "{ match = { class = '(^emacs)' }, workspace = 'name:editors' }"
            "{ match = { class = '(^nvim)' }, workspace = 'name:editors' }"
            "{ match = { class = '(^thunar)' }, workspace = 'name:editors' }"
            "{ match = { class = '(^obsidian)' }, workspace = 'name:editors' }"
            # media/browser
            "{ match = { class = '(^zen)' }, workspace = 'name:media' }"
            "{ match = { class = '(^mpv)' }, workspace = 'name:media' }"
            # terminal/ai/research
            "{ match = { class = '(^ghostty)' }, workspace = 'name:terminal' }"
          ]
        );
      in
      {
        wayland.windowManager.hyprland = {
          settings = {
            bind = namedBinds ++ namedMoveBinds ++ workspaceBinds ++ relativeBinds;
          };
          extraConfig = windowRuleLua;
        };
      };
  };
}
