{ inputs, ... }:
{
  flake-file.inputs.noctalia = {
    url = "github:noctalia-dev/noctalia";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  lix.noctalia = {
    provides.to-hosts.nixos = {
      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;
    };
    homeManager = {
      imports = [
        inputs.noctalia.homeModules.default
      ];
      programs.noctalia = {
        enable = true;
        settings = {
          config_version = 2;

          bar = {
            order = [ "Top" ];
            Top = {
              end = [ "media" "notifications" "bluetooth" "volume" "brightness" "battery" ];
              layer = "overlay";
              margin_ends = 0;
              padding = 39;
              radius = 9;
              radius_bottom_left = 42;
              radius_bottom_right = 42;
              radius_top_left = 0;
              radius_top_right = 0;
              start = [ "launcher" "wallpaper" "workspaces" "cat" ];
              thickness = 25;
              widget_spacing = 5;
            };
          };

          control_center.calendar.show_events_card = false;

          desktop_widgets = {
            schema_version = 2;
            widget_order = [
              "desktop-widget-0000000000000001"
              "desktop-widget-0000000000000003"
              "desktop-widget-0000000000000004"
              "desktop-widget-0000000000000005"
            ];

            grid = {
              cell_size = 16;
              major_interval = 4;
              visible = true;
            };

            widget = {
              "desktop-widget-0000000000000001" = {
                box_height = 224.0;
                box_width = 352.0;
                cx = 1664.0;
                cy = 940.0;
                output = "eDP-1";
                rotation = -0.0;
                type = "clock";
                settings = {
                  background = false;
                  background_color = "surface";
                  background_opacity = 0.80000000000000004;
                  background_padding = 10;
                  background_radius = 12;
                  center_text = false;
                  circle = true;
                  clock_style = "digital";
                  color = "on_surface";
                  font_family = "";
                  format = "{:%H:%M}";
                  shadow = false;
                  timezone = "";
                };
              };

              "desktop-widget-0000000000000003" = {
                box_height = 224.0;
                box_width = 384.0;
                cx = 256.0;
                cy = 940.0;
                output = "eDP-1";
                rotation = 0.0;
                type = "sysmon";
                settings = {
                  stat = "cpu_usage";
                  stat2 = "cpu_temp";
                };
              };

              "desktop-widget-0000000000000004" = {
                box_height = 720.0;
                box_width = 1056.0;
                cx = 960.0;
                cy = 540.0;
                output = "eDP-1";
                rotation = 0.0;
                type = "fancy_audio_visualizer";
                settings.background = false;
              };

              "desktop-widget-0000000000000005" = {
                box_height = 0.0;
                box_width = 0.0;
                cx = 960.0;
                cy = 970.0;
                output = "eDP-1";
                rotation = 0.0;
                type = "media_player";
              };
            };
          };

          dock = {
            active_monitor_only = true;
            active_scale = 1.75;
            auto_hide = true;
            enabled = true;
            icon_size = 27;
            inactive_scale = 1.0;
            launcher_position = "start";
            main_axis_padding = 6;
            reserve_space = false;
          };

          location.auto_locate = true;

          lockscreen_widgets = {
            enabled = false;
            schema_version = 2;
            widget_order = [ "lockscreen-login-box@eDP-1" ];

            grid = {
              cell_size = 16;
              major_interval = 4;
              visible = true;
            };

            widget."lockscreen-login-box@eDP-1" = {
              box_height = 70.0;
              box_width = 400.0;
              cx = 960.0;
              cy = 961.0;
              output = "eDP-1";
              rotation = 0.0;
              type = "login_box";
              settings = {
                background_color = "surface_variant";
                background_opacity = 0.88;
                background_radius = 12.0;
                center_password_text = false;
                input_opacity = 1.0;
                input_radius = 6.0;
                show_caps_lock = true;
                show_keyboard_layout = true;
                show_login_button = true;
                show_password_hint = true;
              };
            };
          };

          plugins.enabled = [ "noctalia/bongocat" ];

          shell = {
            corner_radius_scale = 1.3000000193715096;

            animation.speed = 2.550000037997961;

            launcher = {
              app_grid = true;
              categories = false;
              show_icons = false;
              providers.calculator.prefix = "";
            };

            panel = {
              clipboard_placement = "attached";
              floating_offset = 11;
              launcher_placement = "attached";
              open_near_click_clipboard = true;
              open_near_click_launcher = true;
              open_near_click_wallpaper = true;
              polkit_placement = "attached";
              transparency_mode = "glass";
            };

            screen_corners.enabled = true;
          };

          theme = {
            builtin = "Catppuccin";
            community_palette = "Catppuccin Mocha Pink";
            source = "community";
            wallpaper_scheme = "m3-content";
          };

          wallpaper = {
            directory = "/home/lunixose/Pictures/wallpaper";

            default.path = "/home/lunixose/Pictures/wallpaper/A_Red_Face_Glowing_by_Merlin_Lightpainting.jpeg";
            last.path = "/home/lunixose/Pictures/wallpaper/A_Red_Face_Glowing_by_Merlin_Lightpainting.jpeg";
            monitors."eDP-1".path = "/home/lunixose/Pictures/wallpaper/A_Red_Face_Glowing_by_Merlin_Lightpainting.jpeg";

            favorite = [
              {
                community_palette = "Catppuccin Mocha Pink";
                palette_source = "community";
                path = "/home/lunixose/Pictures/wallpaper/A_Red_Face_Glowing_by_Merlin_Lightpainting.jpeg";
                theme_mode = "dark";
              }
              {
                community_palette = "Catppuccin Mocha Pink";
                palette_source = "community";
                path = "/home/lunixose/Pictures/wallpaper/16.png";
                theme_mode = "dark";
              }
            ];
          };

          widget.cat.type = "noctalia/bongocat:cat";
        };
      };
    };
  };
}
