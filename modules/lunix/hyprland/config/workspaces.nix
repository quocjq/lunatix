# Hyprland workspace bindings and rules.
#
# Multi-monitor layout:
#   Monitor 1 → workspaces 11-19, bound to SUPER + [1-9]
#   Monitor 2 → workspaces 21-29, bound to SUPER + ALT + [1-9]
#   Monitor 3 → workspaces 31-39, bound to SUPER + CTRL + [1-9]
#
# Monitors are declared on the host via freeform attribute:
#   den.hosts.x86_64-linux.igloo.hyprlandMonitors = [
#     { output = "eDP-1"; }
#     { output = "HDMI-A-1"; }
#   ];
#
# If hyprlandMonitors is absent the aspect falls back to a single
# anonymous monitor so the config still evaluates on any host.

{
  den,
  lib,
  ...
}:
{
  lix.hyprland =
    { host, ... }:
    let
      # ------------------------------------------------------------------ #
      # Monitor list — read from host freeform attr, default to one monitor #
      # ------------------------------------------------------------------ #
      monitors =
        if host ? hyprlandMonitors && host.hyprlandMonitors != [ ] then
          host.hyprlandMonitors
        else
          [ { output = null; } ]; # single anonymous monitor

      mainMod = "SUPER";
      digits = [
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
      ];

      # Modifier prefix per monitor index (0-based)
      # Index 0 → no extra mod, 1 → ALT, 2 → CTRL
      monModifiers = [
        ""
        "ALT"
        "CTRL"
      ];

      # ------------------------------------------------------------------ #
      # Workspace rules                                                      #
      # ------------------------------------------------------------------ #
      # Each monitor gets 9 workspaces: <monitorIndex+1><digit>
      # e.g. monitor 0 → "11".."19", monitor 1 → "21".."29"
      # The first workspace of each monitor is set as default.
      # Workspace "13" (3rd ws of monitor 0) gets the scrolling layout.
      workspaceRules = lib.flatten (
        lib.imap0 (
          monIdx: mon:
          lib.imap0 (
            digitIdx: digit:
            let
              wsId = "${toString (monIdx + 1)}${digit}";
              isDefault = digitIdx == 0;
              isScrolling = digitIdx == 2 && monIdx == 0;
            in
            lib.optional (mon.output != null) {
              workspace = wsId;
              monitor = mon.output;
            }
            ++ lib.optional isDefault {
              workspace = wsId;
              default = true;
            }
            ++ lib.optional isScrolling {
              workspace = wsId;
              layout = "scrolling";
            }
          ) digits
        ) (lib.take 3 monitors)
      );

      # ------------------------------------------------------------------ #
      # Workspace bindings                                                   #
      # ------------------------------------------------------------------ #
      # Primary monitor: SUPER+<digit> / SUPER+SHIFT+<digit>
      # Secondary monitors: SUPER+<MOD>+<digit> / SUPER+<MOD>+SHIFT+<digit>
      workspaceBinds = lib.flatten (
        lib.imap0 (
          monIdx: mon:
          let
            prefix = toString (monIdx + 1);
            extraMod = lib.elemAt monModifiers monIdx;
            hasExtraMod = extraMod != "";
            isPrimary = monIdx == 0;

            # Build a single bind attrset (hyprland-nix _args style)
            mkBind = keys: dispatcher: {
              _args = [
                keys
                dispatcher
              ];
            };

            focusBind =
              ws:
              mkBind (
                if isPrimary then "${mainMod}, ${ws}" else "${mainMod} ${extraMod}, ${ws}"
              ) "workspace, ${prefix}${ws}";

            moveBind =
              ws:
              mkBind (
                if isPrimary then "${mainMod} SHIFT, ${ws}" else "${mainMod} ${extraMod} SHIFT, ${ws}"
              ) "movetoworkspacesilent, ${prefix}${ws}";
          in
          lib.flatten (
            map (digit: [
              (focusBind digit)
              (moveBind digit)
            ]) digits
          )
        ) (lib.take 3 monitors)
      );

      # ------------------------------------------------------------------ #
      # Relative navigation (page up / down)                                #
      # ------------------------------------------------------------------ #
      relativeBinds = [
        {
          _args = [
            "${mainMod}, Prior"
            "workspace, r-1"
          ];
        }
        {
          _args = [
            "${mainMod}, Next"
            "workspace, r+1"
          ];
        }
      ];

    in
    {
      homeManager = {
        wayland.windowManager.hyprland.settings = {
          workspace_rules = workspaceRules;
          bind = workspaceBinds ++ relativeBinds;
        };
      };
    };
}
