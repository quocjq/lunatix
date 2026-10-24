{config, ...}: {
  config.vim.languages.typescript = {   # ← renamed from .ts
    enable = true;

    treesitter = {
      enable = true;
    };

    lsp = {
      enable = true;
      servers = ["typescript-language-server"];   # ← renamed from "ts_ls"
    };

    format = {
      enable = true;
      type = ["prettier"];
    };

    extraDiagnostics = {
      enable = true;
      types = ["eslint_d"];
    };

    extensions.ts-error-translator = {
      enable = true;
      setupOpts = {
        auto_override_publish_diagnostics = true;
      };
    };
  };
}
