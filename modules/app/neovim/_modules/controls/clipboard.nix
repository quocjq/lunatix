{ pkgs, ... }: {
  config.vim = {
    clipboard = {
      enable = true;
      registers = "unnamedplus";
      providers = {
        # Wayland (Hyprland, Sway, GNOME/KDE Wayland)
        wl-copy.enable = pkgs.stdenv.isLinux;
        # X11 / XWayland
        xclip.enable = pkgs.stdenv.isLinux;
      };
    };

    luaConfigRC.atomic-clipboard = ''
      if (os.getenv('SSH_TTY') or os.getenv('SSH_CONNECTION'))
        and not os.getenv('WAYLAND_DISPLAY') and not os.getenv('DISPLAY') then
        local osc52 = require('vim.ui.clipboard.osc52')
        vim.g.clipboard = {
          name = 'OSC 52',
          copy = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
          paste = { ['+'] = osc52.paste('+'), ['*'] = osc52.paste('*') },
        }
      end
    '';

    keymaps = [
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>y";
        action = "\"+y";
        desc = "Yank to system clipboard";
      }
      {
        mode = "n";
        key = "<leader>Y";
        action = "\"+y$";
        desc = "Yank to end of line (system clipboard)";
      }
      {
        mode = "v";
        key = "<C-S-c>";
        action = "\"+y";
        desc = "Copy selection to system clipboard";
      }
      {
        mode = "t";
        key = "<C-S-v>";
        action = "<C-\\><C-n>\"+pi";
        desc = "Paste system clipboard into terminal";
      }
    ];
  };
}
