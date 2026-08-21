local scheme = require("scheme.current")

return {
    ------------------
    ---- HYPRLAND ----
    ------------------

    -- Apps
    terminal                   = "ghostty",
    browser                    = "zen-twilight",
    editor                     = "emacs",
    fileExplorer               = "thunar",
    audioSettings              = "pwvucontrol",

    -- Touchpad
    touchpadDisableTyping      = true,
    touchpadScrollFactor       = 0.3,
    gestureFingers             = 3,
    workspaceSwipeFingers      = 4,
    gestureFingersMore         = 4,

    -- Blur
    blurEnabled                = true,
    blurSpecialWs              = false,
    blurPopups                 = true,
    blurInputMethods           = true,
    blurSize                   = 3,
    blurPasses                 = 1,
    blurXray                   = false,

    -- Shadow
    shadowEnabled              = true,
    shadowRange                = 4,
    shadowRenderPower          = 3,
    shadowColour               = "rgba(" .. scheme.inversePrimary .. "10)",

    -- Gaps
    workspaceGaps              = 10,
    windowGapsIn               = 4,
    windowGapsOut              = 10,
    singleWindowGapsOut        = 10,

    -- Window styling
    windowOpacity              = 1.0,
    windowRounding             = 10,
    windowBorderSize           = 1,
    activeWindowBorderColour   = "rgb(" .. scheme.primary .. ")",
    inactiveWindowBorderColour = "rgb(" .. scheme.onSurfaceVariant .. ")",

    -- Misc
    volumeStep                 = 5,
    volumeMax                  = 140,
    cursorTheme                = "breeze_cursors",
    cursorSize                 = 24,
    sleepGestureCmd            = "systemctl suspend-then-hibernate",
    iconTheme                  = "breeze-dark",

    ------------------
    ---- KEYBINDS ----
    ------------------

    -- Modifier only, the actual binds will be mod + 0-9. These should be strings and not arrays.
    kbGoToWs                   = "SUPER",
    kbGoToWsGroup              = "CTRL + SUPER",
    kbMoveWinToWs              = "SUPER + ALT",
    kbMoveWinToWsGroup         = "CTRL + SUPER + ALT",

    -- All the following binds can be either an array of binds to bind multiple keys, or a single string.

    -- Workspaces
    kbMoveWinToWsSpecial       = "SUPER + ALT + S",
    kbMoveWinFromWsSpecial     = "CTRL + SUPER + SHIFT + Down",
    kbMoveWinToWsNext          = "SUPER + ALT + mouse_down",
    kbMoveWinToWsPrev          = "SUPER + ALT + mouse_up",
    kbNextWs                   = "SUPER + mouse_down",
    kbPrevWs                   = "SUPER + mouse_up",
    kbNextWsGroup              = "CTRL + SUPER + mouse_down",
    kbPrevWsGroup              = "CTRL + SUPER + mouse_up",

    -- Window Group
    kbWindowCycleNext          = "ALT + TAB",
    kbWindowCyclePrev          = "SHIFT + ALT + TAB",
    kbWindowGroupCycleNext     = "CTRL + ALT + TAB",
    kbWindowGroupCyclePrev     = "CTRL + SHIFT + ALT + TAB",
    kbUngroup                  = "SUPER + U",
    kbToggleGroup              = "SUPER + Comma",
    kbGroupLockActive          = "SUPER + SHIFT + Comma",

    -- Window Actions
    kbWindowDecreaseWidth      = "SUPER + Minus",
    kbWindowIncreaseWidth      = "SUPER + Equal",
    kbWindowDecreaseHeight     = "SUPER + SHIFT + Minus",
    kbWindowIncreaseHeight     = "SUPER + SHIFT + Equal",

    kbMoveWindow               = "SUPER + Z",
    kbResizeWindow             = "SUPER + X",
    kbCenterWindow             = "CTRL + SUPER + Backslash",
    kbNormalizeWindow          = "CTRL + SUPER + ALT + Backslash",
    kbWindowPip                = "SUPER + ALT + Backslash",
    kbPinWindow                = "SUPER + P",
    kbWindowFullscreen         = "SUPER + F",
    kbWindowBorderedFullscreen = "SUPER + ALT + F",
    kbToggleWindowFloating     = "SUPER + ALT + Space",
    kbCloseWindow              = "SUPER + Q",

    -- Special workspaces toggles
    kbSpecialWs                = "SUPER + S",
    kbSystemMonitorWs          = "CTRL + SHIFT + Escape",
    kbMusicWs                  = "SUPER + M",
    kbCommunicationWs          = "SUPER + D",
    kbTodoWs                   = "SUPER + R",

    -- Apps
    kbTerminal                 = "SUPER + T",
    kbBrowser                  = "SUPER + B",
    kbEditor                   = "SUPER + SHIFT + E",
    kbEmacsClient              = "SUPER + Return",
    kbFileExplorer             = "SUPER + E",
    kbAudioSettings            = "CTRL + ALT + V",

    -- Utilities
    kbScreenshot               = "Print",
    kbScreenshotFreeze         = "SUPER + Print",
    kbScreenshotRegion         = "SUPER + SHIFT + S",
    kbRecord                   = "CTRL + ALT + R",
    kbRecordSound              = "SUPER + ALT + R",
    kbRecordRegion             = "SUPER + SHIFT + ALT + R",
    kbColorPicker              = "SUPER + SHIFT + C",

    -- Media
    kbMediaToggle              = "CTRL + SUPER + Space",
    kbMediaNext                = "CTRL + SUPER + Equal",
    kbMediaPrev                = "CTRL + SUPER + Minus",
    kbMediaStop                = "CTRL + SUPER + Backspace",
    kbVolumeMute               = "SUPER + SHIFT + M",

    -- Misc
    kbLauncher                 = "SUPER + Space",
    kbSession                  = "SUPER + X",
    kbDashboard                = "SUPER + N",
    kbNexus                    = "SUPER + C",
    kbShowSidebar              = "SUPER + SHIFT + N",
    kbClearNotifs              = "CTRL + ALT + C",
    kbShowPanels               = "SUPER + SHIFT + P",
    kbLock                     = "SUPER + L",
    kbRestoreLock              = "SUPER + ALT + L",
    kbSleep                    = "SUPER + SHIFT + L",

    -- Clipboard and emoji picker
    kbClipboard                = "SUPER + V",
    kbClipboardDel             = "SUPER + ALT + V",
    kbClipboardPasteLatest     = "CTRL + SHIFT + ALT + V",
    kbEmoji                    = "SUPER + Period",
}
