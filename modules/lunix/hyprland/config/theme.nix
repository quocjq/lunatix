{ ... }:
{
  # Hyprland non-color decoration knobs only.
  # Colors (border, shadow, groupbar, gradients) come from the stylix
  # `hyprland` target. Cursor env vars come from stylix `home.pointerCursor`.
  lix.hyprland.homeManager = {
    wayland.windowManager.hyprland = {
      settings = {
        config = {
          decoration = {
            rounding = 10;
            blur = {
              enabled = true;
              size = 3;
              passes = 1;
            };
            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
            };
          };
        };
      };
    };
  };
}
