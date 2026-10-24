{ ... }: {
  config.vim = {
    git.gitsigns = {
      enable = true;

      mappings = {
        toggleBlame = "<leader>hB";
        toggleDeleted = "<leader>hx";
      };

      setupOpts = {
        current_line_blame = false;
        current_line_blame_opts.delay = 300;
      };
    };

    utility.diffview-nvim.enable = true;

    luaConfigRC.atomic-diffview-toggle = ''
      local function view_kind(view)
        local ok, name = pcall(function() return view.class:name() end)
        if ok and type(name) == "string" then return name end
        return "unknown"
      end

      -- kind: "DiffView" (git diff) or "FileHistoryView" (git log)
      function _G.atomic_diffview_toggle(cmd, kind)
        local ok, lib = pcall(require, "diffview.lib")
        if not ok then
          vim.cmd(cmd)
          return
        end

        for _, view in ipairs(lib.views) do
          if view_kind(view) == kind then
            pcall(function()
              view:close()
              lib.dispose_view(view)
            end)
            return
          end
        end

        vim.cmd(cmd)
      end

      function _G.atomic_diffview_close()
        local ok, lib = pcall(require, "diffview.lib")
        if not ok then return end

        local open = {}
        for _, view in ipairs(lib.views) do
          open[#open + 1] = view
        end

        for _, view in ipairs(open) do
          pcall(function()
            view:close()
            lib.dispose_view(view)
          end)
        end
      end
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>gd";
        action = "<cmd>lua _G.atomic_diffview_toggle('DiffviewOpen', 'DiffView')<CR>";
        desc = "Git diff of the working tree (toggle)";
      }
      {
        mode = "n";
        key = "<leader>gD";
        action = "<cmd>lua _G.atomic_diffview_toggle('DiffviewOpen HEAD~1', 'DiffView')<CR>";
        desc = "Git diff against the previous commit (toggle)";
      }
      {
        mode = "n";
        key = "<leader>gh";
        action = "<cmd>lua _G.atomic_diffview_toggle('DiffviewFileHistory', 'FileHistoryView')<CR>";
        desc = "Git log of the repository (toggle)";
      }
      {
        mode = "n";
        key = "<leader>gf";
        action = "<cmd>lua _G.atomic_diffview_toggle('DiffviewFileHistory %', 'FileHistoryView')<CR>";
        desc = "Git log of the current file (toggle)";
      }
      {
        mode = "v";
        key = "<leader>gf";
        action = "<Esc><cmd>'<,'>DiffviewFileHistory<CR>";
        desc = "Git log of the selected lines";
      }
      {
        mode = "n";
        key = "<leader>gq";
        action = "<cmd>lua _G.atomic_diffview_close()<CR>";
        desc = "Close Diffview (from anywhere)";
      }
    ];

    binds.whichKey.register = {
      "<leader>g" = "Git";
      "<leader>h" = "Git hunks (gitsigns)";
    };
  };
}
