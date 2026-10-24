{ pkgs, config, ... }:
{
  # Enable bufferline for visual buffer management
  config.vim.tabline.nvimBufferline = {
    enable = true;

    # Key mappings for buffer navigation and management
    mappings = {
      cycleNext = "<Tab>"; # Next buffer
      cyclePrevious = "<S-Tab>"; # Previous buffer
      moveNext = "<leader>>"; # Move buffer right
      movePrevious = "<leader><"; # Move buffer left
      closeCurrent = "<leader>x"; # Close current buffer
      pick = "<leader>bp"; # Pick buffer interactively
      sortByDirectory = "<leader>bsd"; # Sort by directory
      sortByExtension = "<leader>bse"; # Sort by extension
      sortById = "<leader>bsi"; # Sort by ID
    };

    # Setup options
    setupOpts = {
      options = {
        mode = "buffers";
        separator_style = "thin";
        always_show_bufferline = true;
        show_buffer_close_icons = true;
        show_close_icon = true;
        color_icons = true;
        diagnostics = "nvim_lsp";

        # Show buffer numbers for easy jumping
        numbers = {
          _type = "lua-inline";
          expr = ''
            function(opts)
              return string.format('%s·%s', opts.raise(opts.id), opts.lower(opts.ordinal))
            end
          '';
        };
      };
    };
  };
}
