{
  lix.hyprland.homeManager = {
    wayland.windowManager.hyprland = {
      settings = {
        env = [
          # XDG Desktop Portal
          {
            _args = [
              "XDG_CURRENT_DESKTOP"
              "Hyprland"
            ];
          }
          {
            _args = [
              "XDG_SESSION_TYPE"
              "wayland"
            ];
          }
          {
            _args = [
              "XDG_SESSION_DESKTOP"
              "Hyprland"
            ];
          }

          # GTK
          {
            _args = [
              "GDK_SCALE"
              "1"
            ];
          }
          {
            _args = [
              "GDK_BACKEND"
              "wayland,x11"
            ];
          }

          # Mozilla
          {
            _args = [
              "MOZ_ENABLE_WAYLAND"
              "1"
            ];
          }

          # Disable appimage launcher by default
          {
            _args = [
              "APPIMAGELAUNCHER_DISABLE"
              "1"
            ];
          }

          # OZONE
          {
            _args = [
              "OZONE_PLATFORM"
              "wayland"
            ];
          }
        ];
      };
    };
  };
}
