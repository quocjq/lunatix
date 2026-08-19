local vars = require("variables")
local fn   = require("utils.functions")

hl.on("hyprland.start", function()
    -- Bluetooth
    hl.exec_cmd("bluetooth")
    -- caelestia
    hl.exec_cmd("caelestia-shell -d")
    -- editor
    hl.exec_cmd("emacsclient -c -a \"\"")
    -- fcitx5 daemon (lotus engine auto-added as addon); use the system
    hl.exec_cmd("/run/current-system/sw/bin/fcitx5 -d")
    -- Cursors
    hl.exec_cmd("hyprctl setcursor " .. vars.cursorTheme .. " " .. vars.cursorSize)
end)

-- Resizer listeners
local function apply_resizer_rules(win)
    local float_center = {
        hl.dsp.window.float({ action = "on", window = win }),
        hl.dsp.window.center({ window = win }),
    }
    local pip_actions = fn.move_actions(win) or {}

    -- Picture in picture
    fn.resizer(win, "Picture[- ]in[- ][Pp]icture", 0, 0, pip_actions, false)
end

hl.on("window.title", apply_resizer_rules)
hl.on("window.open", apply_resizer_rules)
