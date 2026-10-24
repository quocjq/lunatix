{pkgs, ...}: {
  config.vim = {
    # window-picker is a hard runtime dependency of Neo-tree's `w` mapping and
    # window-picker splits; without it they just print an error at runtime.
    extraPlugins = {
      window-picker = {
        package = pkgs.vimPlugins.nvim-window-picker;
        setup = ''
          require('window-picker').setup({
            hint = 'floating-big-letter',
            show_prompt = false,
            filter_rules = {
              autoselect_one = true,
              include_current_win = false,
              bo = {
                filetype = { 'neo-tree', 'neo-tree-popup', 'notify', 'codecompanion' },
                buftype = { 'terminal', 'quickfix', 'prompt' },
              },
            },
          })
        '';
      };
    };

    filetree.neo-tree = {
      enable = true;
      setupOpts = {
        close_if_last_window = true;
        filesystem = {
          follow_current_file.enabled = true;
          use_libuv_file_watcher = true;
        };
        window.mappings = {
          "Y" = {
            _type = "lua-inline";
            expr = ''
              {
                function(state)
                  local path = state.tree:get_node():get_id()
                  vim.fn.setreg("+", path)
                  vim.notify("Copied: " .. path)
                end,
                desc = "copy path to system clipboard",
              }
            '';
          };
        };
      };
    };

    autocmds = [
      {
        event = ["FileType"];
        pattern = ["neo-tree"];
        desc = "Line numbers inside Neo-tree";
        callback = {
          _type = "lua-inline";
          expr = ''
            function(ev)
              -- Neo-tree recreates its window on every open, and FileType fires
              -- before it finishes mounting; scheduling applies the option to
              -- the final window instead of one that gets thrown away.
              vim.schedule(function()
                local win = vim.fn.bufwinid(ev.buf)
                if win == -1 then return end
                vim.wo[win].number = true
                vim.wo[win].relativenumber = true
              end)
            end
          '';
        };
      }
      {
        event = ["BufDelete"];
        pattern = ["*"];
        desc = "Close Neo-tree when a buffer is closed";
        callback = {
          _type = "lua-inline";
          expr = ''
            function(ev)
              local buf = ev.buf
              -- Skip special buffers (terminal, neo-tree, chat, telescope...) and
              -- the empty [No Name] buffer Neovim discards when opening a file.
              if vim.bo[buf].buftype ~= "" or not vim.bo[buf].buflisted then return end
              if vim.api.nvim_buf_get_name(buf) == "" then return end
              vim.schedule(function()
                if package.loaded["neo-tree"] then
                  pcall(vim.cmd, "Neotree close")
                end
              end)
            end
          '';
        };
      }
    ];
  };
}
