{
  config,
  pkgs,
  ...
}: {
  config.vim = {
    extraPlugins = {
      solarized = {
        package = pkgs.vimPlugins.solarized-nvim;
        setup = ''require('solarized').set()'';
      };
    };

    luaConfigRC.theme-persistence = ''
      -- Theme persistence configuration
      local DEFAULT_THEME = 'solarized'
      local DEFAULT_LUALINE = 'solarized_light'

      local THEME_MAP = {
        solarized = 'solarized_light', gruvbox = 'gruvbox', tokyonight = 'tokyonight',
        catppuccin = 'catppuccin', nord = 'nord', onedark = 'onedark',
        nightfox = 'nightfox', kanagawa = 'kanagawa',
      }

      -- Config file path
      local config_dir = os.getenv('XDG_CONFIG_HOME') and
        os.getenv('XDG_CONFIG_HOME') .. '/nvim' or
        (os.getenv('HOME') and os.getenv('HOME') .. '/.config/nvim' or vim.fn.stdpath('config'))
      local theme_file = config_dir .. '/atomic_theme.json'
      vim.fn.mkdir(config_dir, 'p')

      -- File operations
      local function read_theme()
        local file = io.open(theme_file, 'r')
        if not file then return DEFAULT_THEME, DEFAULT_LUALINE end

        local content = file:read('*all')
        file:close()

        if content == "" then return DEFAULT_THEME, DEFAULT_LUALINE end

        local ok, config = pcall(vim.json.decode, content)
        if ok and config then
          return config.theme or DEFAULT_THEME, config.lualine or DEFAULT_LUALINE
        end
        return DEFAULT_THEME, DEFAULT_LUALINE
      end

      local function write_theme(theme, lualine_theme)
        local config = { theme = theme, lualine = lualine_theme, timestamp = os.time() }
        local ok, json_str = pcall(vim.json.encode, config)
        if not ok then return false end

        local file = io.open(theme_file, 'w')
        if file then
          file:write(json_str)
          file:close()
          return true
        end
        return false
      end

      -- Main theme function
      function _G.change_theme(theme_name, lualine_theme)
        local ok = pcall(vim.cmd, 'colorscheme ' .. theme_name)
        if not ok then
          vim.notify('Theme "' .. theme_name .. '" not found', vim.log.levels.ERROR)
          return false
        end

        lualine_theme = lualine_theme or THEME_MAP[theme_name] or 'auto'
        local lualine_ok, lualine = pcall(require, 'lualine')
        if lualine_ok then
          pcall(lualine.setup, { options = { theme = lualine_theme } })
        end

        local saved = write_theme(theme_name, lualine_theme)
        vim.notify('Theme: ' .. theme_name .. (saved and ' (saved)' or ' (not saved)'),
          saved and vim.log.levels.INFO or vim.log.levels.WARN)
        return true
      end

      -- Apply saved theme on startup
      local saved_theme, saved_lualine = read_theme()
      vim.defer_fn(function() change_theme(saved_theme, saved_lualine) end, 100)

      -- Telescope picker
      vim.defer_fn(function()
        local ok, telescope = pcall(require, 'telescope')
        if not ok then return end

        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')
        local pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local conf = require('telescope.config')

        local function colorscheme_picker(opts)
          local current_theme = vim.g.colors_name or saved_theme

          pickers.new(opts or {}, {
            prompt_title = '🎨 Choose Colorscheme',
            finder = finders.new_table({ results = vim.fn.getcompletion("", "color") }),
            sorter = conf.values.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr, map)
              -- Select theme
              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection then change_theme(selection[1]) end
              end)

              -- Preview and restore functions
              local function preview()
                local selection = action_state.get_selected_entry()
                if selection then pcall(vim.cmd, 'colorscheme ' .. selection[1]) end
              end

              local function restore_and_close()
                pcall(vim.cmd, 'colorscheme ' .. current_theme)
                actions.close(prompt_bufnr)
              end

              -- Keybindings
              map({'i', 'n'}, '<CR>', actions.select_default)
              map({'i', 'n'}, '<Esc>', restore_and_close)
              map('n', 'q', restore_and_close)

              vim.api.nvim_create_autocmd('CursorMoved', {
                buffer = prompt_bufnr,
                callback = preview,
              })

              return true
            end,
          }):find()
        end

        _G.colorscheme_picker = colorscheme_picker
        vim.api.nvim_create_user_command('ThemePicker', colorscheme_picker, {})
      end, 200)

      -- Utility commands
      vim.api.nvim_create_user_command('Theme', function(opts)
        change_theme(opts.args)
      end, { nargs = 1, complete = 'color' })

      vim.api.nvim_create_user_command('ThemeDebug', function()
        vim.notify('Config: ' .. theme_file .. ' | Current: ' .. (vim.g.colors_name or 'none'))
      end, {})

      vim.api.nvim_create_user_command('ThemeReset', function()
        change_theme(DEFAULT_THEME, DEFAULT_LUALINE)
      end, {})
    '';

    statusline.lualine = {
      enable = true;
      theme = "solarized_light";
    };
  };
}
