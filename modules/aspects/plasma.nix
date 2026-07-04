{ inputs, ... }:
{
  flake-file.inputs.plasma-manager = {
    url = "github:nix-community/plasma-manager";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      home-manager.follows = "home-manager";
    };
  };

  den.aspects.plasma = {
    provides.to-hosts.nixos = {
      services.desktopManager.plasma6.enable = true;
    };
    homeManager = { pkgs, ... }: {
      imports = [
        inputs.plasma-manager.homeModules.plasma-manager
      ];
      programs.plasma = {
        enable = true;
        workspace = {
          clickItemTo = "select";
          cursor = {
            animationTime = 5;
            cursorFeedback = "Bouncing";
            size = 24;
            taskManagerFeedback = true;
            theme = "Breeze_Snow";
          };
          iconTheme = "breeze-dark";
          wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Kay/contents/images/1080x1920.png";
          soundTheme = "freedesktop";
          splashScreen.engine = "none";
          splashScreen.theme = "None";
          theme = "breeze-dark";
        };

        hotkeys.commands."launch-konsole" = {
          name = "Launch Konsole";
          key = "Meta+Return";
          command = "konsole";
        };

        fonts = {
          general = {
            family = "JetBrains Mono";
            pointSize = 12;
          };
        };

        panels = [
          {
            location = "top";
            height = 26;
            widgets = [
              {
                applicationTitleBar = {
                  behavior = {
                    activeTaskSource = "activeTask";
                  };
                  layout = {
                    elements = [ "windowTitle" ];
                    horizontalAlignment = "left";
                    showDisabledElements = "deactivated";
                    verticalAlignment = "center";
                  };
                  overrideForMaximized.enable = false;
                  titleReplacements = [
                    {
                      type = "regexp";
                      originalTitle = ''\\bDolphin\\b'';
                      newTitle = "File manager";
                    }
                  ];
                  windowTitle = {
                    font = {
                      bold = false;
                      fit = "fixedSize";
                      size = 12;
                    };
                    hideEmptyTitle = true;
                    margins = {
                      bottom = 0;
                      left = 10;
                      right = 5;
                      top = 0;
                    };
                    source = "appName";
                  };
                };
              }
              "org.kde.plasma.appmenu"
              "org.kde.plasma.panelspacer"
              {
                digitalClock = {
                  date.enable = false;
                  calendar.firstDayOfWeek = "monday";
                  time.format = "24h";
                  font = {
                    family = "JetBrains Mono ExtraBold";
                    bold = true;
                    italic = true;
                  };
                };
              }
              "org.kde.plasma.panelspacer"
              {
                plasmusicToolbar = {
                  panelIcon = {
                    albumCover = {
                      useAsIcon = false;
                      radius = 8;
                    };
                    icon = "view-media-track";
                  };
                  playbackSource = "auto";
                  musicControls.showPlaybackControls = false;
                  songText = {
                    displayInSeparateLines = true;
                    maximumWidth = 200;
                    scrolling = {
                      behavior = "alwaysScroll";
                      speed = 4;
                    };
                  };
                };
              }
              {
                systemTray.items = {
                  shown = [
                    "org.kde.plasma.battery"
                    "org.kde.plasma.bluetooth"
                  ];
                  hidden = [
                    "org.kde.plasma.networkmanagement"
                    "org.kde.plasma.volume"
                  ];
                };
              }
            ];
          }
        ];

        window-rules = [
          {
            description = "Dolphin";
            match = {
              window-class = {
                value = "dolphin";
                type = "substring";
              };
              window-types = [ "normal" ];
            };
            apply = {
              noborder = {
                value = true;
                apply = "force";
              };
              # `apply` defaults to "apply-initially"
              maximizehoriz = true;
              maximizevert = true;
            };
          }
        ];

        powerdevil = {
          AC = {
            powerButtonAction = "lockScreen";
            autoSuspend = {
              action = "shutDown";
              idleTimeout = 1000;
            };
            turnOffDisplay = {
              idleTimeout = 1000;
              idleTimeoutWhenLocked = "immediately";
            };
          };
          battery = {
            powerButtonAction = "sleep";
            whenSleepingEnter = "standbyThenHibernate";
          };
          lowBattery = {
            whenLaptopLidClosed = "hibernate";
          };
        };

        kwin = {
          edgeBarrier = 0; # Disables the edge-barriers introduced in plasma 6.1
          cornerBarrier = false;
          scripts.polonium.enable = true;
        };

        kscreenlocker = {
          lockOnResume = true;
          timeout = 10;
        };

        #
        # Some mid-level settings: Auto generated by `nix run github:nix-community/plasma-manager/trunk#rc2nix`
        #

        shortcuts = {
          "KDE Keyboard Layout Switcher"."Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
          "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Meta+Alt+K";
          kaccess."Toggle Screen Reader On and Off" = "Meta+Alt+S";
          kmix.decrease_microphone_volume = "Microphone Volume Down";
          kmix.decrease_volume = "Volume Down";
          kmix.decrease_volume_small = "Shift+Volume Down";
          kmix.increase_microphone_volume = "Microphone Volume Up";
          kmix.increase_volume = "Volume Up";
          kmix.increase_volume_small = "Shift+Volume Up";
          kmix.mic_mute = [
            "Microphone Mute"
            "Meta+Volume Mute"
          ];
          kmix.mute = "Volume Mute";
          ksmserver."Lock Session" = [
            "Screensaver"
            "Meta+L"
          ];
          ksmserver."Log Out" = "Ctrl+Alt+Del";
          kwin."Activate Window Demanding Attention" = "Meta+Ctrl+A";
          kwin.Expose = "Meta+\\";
          kwin.ExposeAll = [
            "Launch (C)"
            "Ctrl+F10"
            "Meta+F10"
          ];
          kwin.ExposeClass = [
            "Ctrl+F7"
            "Meta+F7"
          ];
          kwin."Grid View" = "Meta+G";
          kwin."Kill Window" = "Meta+Ctrl+Esc";
          kwin.MoveMouseToCenter = "Meta+F6";
          kwin.MoveMouseToFocus = "Meta+F5";
          kwin.Overview = "Meta+W";
          kwin.PoloniumActivateAbove = "Meta+K";
          kwin.PoloniumActivateBelow = "Meta+J";
          kwin.PoloniumActivateLeft = "Meta+H";
          kwin.PoloniumActivateRight = "Meta+L";
          kwin.PoloniumPlaceAbove = "Meta+Shift+K";
          kwin.PoloniumPlaceBelow = "Meta+Shift+J";
          kwin.PoloniumPlaceLeft = "Meta+Shift+H";
          kwin.PoloniumPlaceRight = "Meta+Shift+L";
          kwin.PoloniumResizeDown = "Meta+Ctrl+J";
          kwin.PoloniumResizeLeft = "Meta+Ctrl+H";
          kwin.PoloniumResizeRight = "Meta+Ctrl+L";
          kwin.PoloniumResizeUp = "Meta+Ctrl+K";
          kwin.PoloniumToggleActiveTiling = "Meta+Shift+Space";
          kwin.PoloniumToggleSettingsMenu = "Meta+\\\\,none";
          kwin."Show Desktop" = "Meta+D";
          kwin."Switch One Desktop Down" = "Meta+Ctrl+Down";
          kwin."Switch One Desktop Up" = "Meta+Ctrl+Up";
          kwin."Switch One Desktop to the Left" = "Meta+Ctrl+Left";
          kwin."Switch One Desktop to the Right" = "Meta+Ctrl+Right";
          kwin."Switch Window Down" = "Meta+J";
          kwin."Switch Window Left" = "Meta+H";
          kwin."Switch Window Right" = "Meta+L";
          kwin."Switch Window Up" = "Meta+K";
          kwin."Switch to Desktop 1" = "Meta+1";
          kwin."Switch to Desktop 2" = "Meta+2";
          kwin."Switch to Desktop 3" = "Meta+3";
          kwin."Switch to Desktop 4" = "Meta+4";
          kwin."Switch to Desktop 5" = "Meta+5";
          kwin."Switch to Desktop 6" = "Meta+6";
          kwin."Switch to Desktop 7" = "Meta+7";
          kwin."Switch to Desktop 8" = "Meta+8";
          kwin."Switch to Desktop 9" = "Meta+9";
          kwin."Walk Through Windows" = [
            "Alt+Tab"
            "Meta+Tab"
          ];
          kwin."Walk Through Windows (Reverse)" = [
            "Alt+Shift+Tab"
            "Meta+Shift+Tab"
          ];
          kwin."Walk Through Windows of Current Application" = [
            "Alt+`"
            "Meta+`"
          ];
          kwin."Walk Through Windows of Current Application (Reverse)" = [
            "Alt+~"
            "Meta+~"
          ];
          kwin."Window Close" = [
            "Alt+F4"
            "Meta+Q"
          ];
          kwin."Window Maximize" = "Meta+PgUp";
          kwin."Window Minimize" = "Meta+PgDown";
          kwin."Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
          kwin."Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
          kwin."Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
          kwin."Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
          kwin."Window Operations Menu" = "Alt+F3";
          kwin."Window Quick Tile Bottom" = "Meta+Down";
          kwin."Window Quick Tile Left" = "Meta+Left";
          kwin."Window Quick Tile Right" = "Meta+Right";
          kwin."Window Quick Tile Top" = "Meta+Up";
          kwin."Window Restore" = "Meta+Backspace";
          kwin."Window to Next Screen" = "Meta+Shift+Right";
          kwin."Window to Previous Desktop" = [ ];
          kwin."Window to Previous Screen" = "Meta+Shift+Left";
          kwin.disableInputCapture = "Meta+Shift+Esc";
          kwin.view_actual_size = "Meta+0";
          kwin.view_zoom_in = [
            "Meta++"
            "Meta+="
          ];
          kwin.view_zoom_out = "Meta+-";
          mediacontrol.nextmedia = "Media Next";
          mediacontrol.pausemedia = "Media Pause";
          mediacontrol.playpausemedia = "Media Play";
          mediacontrol.previousmedia = "Media Previous";
          mediacontrol.seekbackwardmedia = "Media Rewind";
          mediacontrol.seekforwardmedia = "Media Fast Forward";
          mediacontrol.stopmedia = "Media Stop";
          org_kde_powerdevil."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
          org_kde_powerdevil."Decrease Screen Brightness" = "Monitor Brightness Down";
          org_kde_powerdevil."Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
          org_kde_powerdevil.Hibernate = "Hibernate";
          org_kde_powerdevil."Increase Keyboard Brightness" = "Keyboard Brightness Up";
          org_kde_powerdevil."Increase Screen Brightness" = "Monitor Brightness Up";
          org_kde_powerdevil."Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
          org_kde_powerdevil.PowerDown = "Power Down";
          org_kde_powerdevil.PowerOff = "Power Off";
          org_kde_powerdevil.Sleep = "Sleep";
          org_kde_powerdevil."Toggle Keyboard Backlight" = "Keyboard Light On/Off";
          org_kde_powerdevil.powerProfile = [
            "Battery"
            "Meta+B"
          ];
          plasmashell."activate application launcher" = [
            "Meta"
            "Alt+F1"
          ];
          plasmashell.clipboard_action = "Meta+Ctrl+X";
          plasmashell.cycle-panels = "Meta+Alt+P";
          plasmashell."next activity" = "Meta+A";
          plasmashell."previous activity" = "Meta+Shift+A";
          plasmashell."show dashboard" = "Ctrl+F12";
          plasmashell.show-on-mouse-pos = "Meta+V";
          "services/org.kde.konsole.desktop"._launch = "Meta+T";
        };
        configFile = {
          kcminputrc.Mouse.cursorSize = 24;
          kdeglobals.General.XftAntialias = true;
          kdeglobals.General.XftHintStyle = "hintslight";
          kdeglobals.General.XftSubPixel = "vbgr";
          kdeglobals.General.fixed = "JetBrains Mono Medium,10,-1,5,500,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0";
          kdeglobals.KDE.SingleClick = false;
          kdeglobals.KDE.contrast = 4;
          kdeglobals.KDE.frameContrast = 0.2;
          kdeglobals."KFileDialog Settings"."Allow Expansion" = false;
          kdeglobals."KFileDialog Settings"."Automatically select filename extension" = true;
          kdeglobals."KFileDialog Settings"."Breadcrumb Navigation" = true;
          kdeglobals."KFileDialog Settings"."Decoration position" = 2;
          kdeglobals."KFileDialog Settings"."Show Full Path" = false;
          kdeglobals."KFileDialog Settings"."Show Inline Previews" = true;
          kdeglobals."KFileDialog Settings"."Show Preview" = false;
          kdeglobals."KFileDialog Settings"."Show Speedbar" = true;
          kdeglobals."KFileDialog Settings"."Show hidden files" = false;
          kdeglobals."KFileDialog Settings"."Sort by" = "Name";
          kdeglobals."KFileDialog Settings"."Sort directories first" = true;
          kdeglobals."KFileDialog Settings"."Sort hidden files last" = false;
          kdeglobals."KFileDialog Settings"."Sort reversed" = false;
          kdeglobals."KFileDialog Settings"."Speedbar Width" = 140;
          kdeglobals."KFileDialog Settings"."View Style" = "DetailTree";
          kdeglobals.Sounds.Theme = "freedesktop";
          kdeglobals.WM.activeBackground = "39,44,49";
          kdeglobals.WM.activeBlend = "252,252,252";
          kdeglobals.WM.activeForeground = "252,252,252";
          kdeglobals.WM.inactiveBackground = "32,36,40";
          kdeglobals.WM.inactiveBlend = "161,169,177";
          kdeglobals.WM.inactiveForeground = "161,169,177";
          klaunchrc.BusyCursorSettings.Blinking = false;
          klaunchrc.BusyCursorSettings.Bouncing = true;
          klaunchrc.BusyCursorSettings.Timeout = 5;
          klaunchrc.FeedbackStyle.BusyCursor = true;
          klaunchrc.FeedbackStyle.TaskbarButton = true;
          klaunchrc.TaskbarButtonSettings.Timeout = 5;
          krunnerrc.General.FreeFloating = true;
          kscreenlockerrc.Daemon.LockOnResume = true;
          kscreenlockerrc.Daemon.Timeout = 10;
          kwinrc.Desktops.Number = 9;
          kwinrc.Desktops.Rows = 1;
          kwinrc.EdgeBarrier.CornerBarrier = false;
          kwinrc.EdgeBarrier.EdgeBarrier = 0;
          kwinrc.Effect-hidecursor.InactivityDuration = 5;
          kwinrc.Effect-translucency.ComboboxPopups = 61;
          kwinrc.Effect-translucency.Dialogs = 91;
          kwinrc.Effect-translucency.DropdownMenus = 61;
          kwinrc.Effect-translucency.ExcludeFullScreen = true;
          kwinrc.Effect-translucency.Inactive = 62;
          kwinrc.Effect-translucency.IndividualMenuConfig = true;
          kwinrc.Effect-translucency.Menus = 61;
          kwinrc.Effect-translucency.MoveResize = 41;
          kwinrc.Effect-translucency.PopupMenus = 80;
          kwinrc.Effect-translucency.TornOffMenus = 53;
          kwinrc.Plugins.blurEnabled = true;
          kwinrc.Plugins.hidecursorEnabled = true;
          kwinrc.Plugins.poloniumEnabled = true;
          kwinrc.Plugins.translucencyEnabled = true;
          kwinrc.Script-polonium.DefaultEngine = 1;
          kwinrc.Windows.AutoRaise = true;
          kwinrc.Windows.AutoRaiseInterval = 0;
          kwinrc.Windows.DelayFocusInterval = 0;
          kwinrc.Windows.FocusPolicy = "FocusFollowsMouse";
          kwinrc.Xwayland.Scale = 1;
          kwinrulesrc."1".Description = "Dolphin";
          kwinrulesrc."1".maximizehoriz = true;
          kwinrulesrc."1".maximizehorizrule = 3;
          kwinrulesrc."1".maximizevert = true;
          kwinrulesrc."1".maximizevertrule = 3;
          kwinrulesrc."1".noborder = true;
          kwinrulesrc."1".noborderrule = 2;
          kwinrulesrc."1".types = 1;
          kwinrulesrc."1".wmclass = "dolphin";
          kwinrulesrc."1".wmclasscomplete = true;
          kwinrulesrc."1".wmclassmatch = 2;
          kxkbrc.Layout.Options = "caps:escape";
          kxkbrc.Layout.ResetOldOptions = true;
          plasmarc.Theme.name = "breeze-dark";
          spectaclerc.ImageSave.translatedScreenshotsFolder = "Screenshots";
          spectaclerc.VideoSave.translatedScreencastsFolder = "Screencasts";
        };
      };
    };
  };
}
