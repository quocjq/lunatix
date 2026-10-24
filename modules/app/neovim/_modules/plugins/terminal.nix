{ ... }: {
  config.vim = {
    terminal.toggleterm = {
      enable = true;

      mappings.open = "<C-t>";

      setupOpts = {
        direction = "horizontal";
        start_in_insert = true;
        persist_mode = false;
        close_on_exit = true;
        shade_terminals = false;
      };
    };

    autocmds = [
      {
        event = [ "TermOpen" ];
        pattern = [ "term://*" ];
        desc = "Local keymaps and options for terminal buffers";
        callback = {
          _type = "lua-inline";
          expr = ''
            function(ev)
              local opts = { buffer = ev.buf, silent = true }
              local function map(lhs, rhs, desc)
                vim.keymap.set("t", lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
              end

              vim.opt_local.number = false
              vim.opt_local.relativenumber = false
              vim.opt_local.signcolumn = "no"

              local name = vim.api.nvim_buf_get_name(ev.buf)
              if not name:match("lazygit") and not name:match("fzf") then
                map("<Esc>", [[<C-\><C-n>]], "Exit terminal mode")
              end
              map("<A-Esc>", "<Esc>", "Send a literal ESC to the terminal program")

              map("<C-h>", [[<Cmd>wincmd h<CR>]], "Go to left window")
              map("<C-j>", [[<Cmd>wincmd j<CR>]], "Go to lower window")
              map("<C-k>", [[<Cmd>wincmd k<CR>]], "Go to upper window")
              map("<C-l>", [[<Cmd>wincmd l<CR>]], "Go to right window")
            end
          '';
        };
      }
      {
        event = [
          "BufWinEnter"
          "WinEnter"
        ];
        pattern = [ "term://*" ];
        desc = "Enter terminal mode when focusing a terminal";
        command = "startinsert";
      }
    ];

    keymaps = [
      {
        mode = "n";
        key = "<leader>tv";
        action = "<cmd>ToggleTerm direction=horizontal<CR>";
        desc = "Toggle terminal (horizontal)";
      }
      {
        mode = "n";
        key = "<leader>tf";
        action = "<cmd>ToggleTerm direction=float<CR>";
        desc = "Toggle terminal (float)";
      }
      {
        mode = "n";
        key = "<leader>ts";
        action = "<cmd>ToggleTerm direction=vertical<CR>";
        desc = "Toggle terminal (vertical)";
      }
      {
        mode = "n";
        key = "<leader>ta";
        action = "<cmd>ToggleTermToggleAll<CR>";
        desc = "Toggle all terminals";
      }
      {
        mode = "v";
        key = "<leader>tl";
        action = "<cmd>ToggleTermSendVisualLines<CR>";
        desc = "Send selected lines to terminal";
      }
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        desc = "Go to left window";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        desc = "Go to lower window";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        desc = "Go to upper window";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        desc = "Go to right window";
      }
    ];
  };
}
