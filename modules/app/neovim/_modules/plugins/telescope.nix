{config, ...}: {
  vim.telescope = {
    enable = true;

    # Atalhos personalizados (opcional — pode remover ou alterar)
    mappings = {
      findFiles = "<leader>ff";
      liveGrep = "<leader>fg";
      buffers = "<leader>fb";
      helpTags = "<leader>fh";
      gitStatus = "<leader>fvs";
      lspReferences = "<leader>flr";
      resume = "<leader>fr";
      # adicione mais se quiser
    };

    # Configurações adicionais
    setupOpts = {
      defaults = {
        prompt_prefix = "  ";
        selection_caret = " ";
        color_devicons = true;
        file_ignore_patterns = [
          "node_modules"
          "%.git/"
          "dist/"
          "build/"
          "target/"
          "result/"
        ];
        initial_mode = "insert";
        layout_strategy = "horizontal";
        layout_config = {
          width = 0.8;
          height = 0.8;
          preview_cutoff = 120;
          horizontal = {
            preview_width = 0.55;
            prompt_position = "top";
          };
          vertical = {
            mirror = false;
          };
        };
        path_display = ["smart"];
      };
    };
  };
}
