{ __findFile, ... }: {
  lix.sioyek = {
    homeManager = {
      programs.sioyek = {
        enable = true;

        # Zathura-style keybinds. Mirrors `man zathurarc`'s common defaults
        # mapped onto sioyek's command set (see
        # https://github.com/ahrm/sioyek/blob/main/pdf_viewer/keys.config).
        # Home-manager renders this as duplicate `<command> <key>` lines
        # in ~/.config/sioyek/keys_user.config.
        bindings = {
          # Page-level navigation (zathura: J/K)
          next_page = [ "J" "<PageDown>" ];
          previous_page = [ "K" "<PageUp>" ];

          # Scroll (zathura: j/k)
          screen_down = [ "j" "d" "<Space>" "<C-d>" ];
          screen_up = [ "k" "u" "<S-Space>" "<C-u>" ];

          # Horizontal scroll (zathura: h/l)
          move_left = "h";
          move_right = "l";

          # Jump to edges (zathura: gg/G)
          goto_beginning = "gg";
          goto_end = "G";

          # Search (zathura: / n N)
          search = [ "/" "<C-f>" ];
          next_item = "n";
          previous_item = "N";

          # Zoom + fit (zathura: + - =)
          zoom_in = [ "+" "<C-ScrollWheelUp>" ];
          zoom_out = [ "-" "<C-ScrollWheelDown>" ];
          fit_to_page_width = "=";

          # Quit + commands (zathura: q)
          quit = "q";
        };

        # Cosmetic prefs. Stylix (modules/lunix/stylix.nix) merges a
        # `toggle_custom_color` startup_command plus the palette into
        # `programs.sioyek.config` — those attrs are not redeclared here
        # so the lists concatenate.
        config = {
          startup_commands = [ "toggle_visual_scroll" ];
        };
      };
    };
  };
}