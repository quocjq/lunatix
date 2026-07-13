{ ... }:
{
  lix.hyprland.homeManager =
    { lib, ... }:
    let
      lua = lib.generators.mkLuaInline;
      mainMod = "SUPER";
      dsp = {
        exec = cmd: lua ''hl.dsp.exec_cmd("${cmd}")'';
        close = lua "hl.dsp.window.close()";
        fullscreen = lua "hl.dsp.window.fullscreen()";
        scrollingUp = lua ''hl.dsp.layout("move +col")'';
        scrollingDown = lua ''hl.dsp.layout("move -col")'';
        mouse = {
          drag = lua "hl.dsp.window.drag()";
          resize = lua "hl.dsp.window.resize()";
          flag = lua "{ mouse = true }";
        };
      };
      bind = keys: dispatcher: {
        _args = [
          keys
          dispatcher
        ];
      };
      bindF = keys: dispatcher: flags: {
        _args = [
          keys
          dispatcher
          flags
        ];
      };
    in
    {
      wayland.windowManager.hyprland = {
        settings = {
          bind = [
            # Actions
            (bind "${mainMod} + Return" (dsp.exec "emacs"))
            (bind "${mainMod} + " (dsp.exec "emacs"))
            (bind "${mainMod} + Q" dsp.close)
            (bind "${mainMod} + F" dsp.fullscreen)
            # (bind "${mainMod} + Space" (dsp.exec "wofi --show drun --allow-images --prompt Applications"))
            # (bind "Print" (dsp.exec "grim -g \\\"$(slurp)\\\" - | wl-copy"))
            # (bind "SHIFT + Print" (
            #   dsp.exec "grim -o $(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name') - | wl-copy"
            # ))
            #(bind "${mainMod} + grave" (dsp.exec "$HOME/.config/hypr/scripts/hdrop.sh --floating --gap 10 --class ddownkit kitty --class ddownkit"))
            #(bind "${mainMod} + ALT + grave" (dsp.exec "$HOME/.config/hypr/scripts/hdrop.sh --floating --gap 10 --class ddownfiles kitty --class ddownfiles yazi"))
            (bind "${mainMod} + C" (dsp.exec "$HOME/.config/hypr/scripts/goxlrMute.sh"))

            (bind "XF86AudioRaiseVolume" (dsp.exec "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"))
            (bind "XF86AudioLowerVolume" (dsp.exec "wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"))
            (bind "XF86AudioMute" (dsp.exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
            (bind "XF86AudioMicMute" (dsp.exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))

            (bindF "${mainMod} + mouse:272" dsp.mouse.drag dsp.mouse.flag)
            (bindF "${mainMod} + mouse:273" dsp.mouse.resize dsp.mouse.flag)
            (bind "${mainMod} + mouse_down" dsp.scrollingDown)
            (bind "${mainMod} + mouse_up" dsp.scrollingUp)
            (bindF "${mainMod} + mouse:275" dsp.scrollingDown dsp.mouse.flag)
            (bindF "${mainMod} + mouse:276" dsp.scrollingUp dsp.mouse.flag)
          ];
        };
      };
    };
}
