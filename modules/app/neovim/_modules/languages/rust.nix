{
  config,
  pkgs,
  ...
}: {
  config.vim.languages.rust = {
    enable = true;

    treesitter = {
      enable = true;
    };

    lsp = {
      enable = true;
      opts = ''
        ['rust-analyzer'] = {
          cargo = {
            allFeatures = true;
          };
          checkOnSave = true;
          procMacro = {
            enable = true;
          };
        }
      '';
    };

    format = {
      enable = true;
      type = ["rustfmt"];
    };

    dap = {
      enable = true;
      package = pkgs.lldb;
    };

    # ← MUDANÇA: nova estrutura para crates
    extensions.crates-nvim = {
      enable = true;
      # ← REMOVIDO: codeActions = true; (não é mais suportado)
      # Se você quiser code actions, configure via setupOpts:
      setupOpts = {
        # Consulte: https://github.com/Saecki/crates.nvim/wiki/Documentation-v0.7.1#in-process-language-server
        lsp = {
          enabled = true;
          actions = true;
          completion = true;
          hover = true;
        };
      };
    };
  };
}
