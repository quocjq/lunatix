{ pkgs, ... }: {
  config.vim = {
    assistant.codecompanion-nvim = {
      enable = true;

      setupOpts = {
        adapters = {
          _type = "lua-inline";
          expr = ''
            {
              http = {
                gemini = function()
                  return require("codecompanion.adapters").extend("gemini", {
                    env = { api_key = "GEMINI_API_KEY" },
                    schema = {
                      model = { default = "gemini-2.5-flash" },
                    },
                  })
                end,
              },
              acp = {
                claude_code = function()
                  return require("codecompanion.adapters").extend("claude_code", {
                    env = { CLAUDE_CODE_OAUTH_TOKEN = "CLAUDE_CODE_OAUTH_TOKEN" },
                  })
                end,
              },
            }
          '';
        };

        interactions = {
          chat.adapter = "gemini";
          inline.adapter = "gemini";
          cmd.adapter = "gemini";
        };

        display = {
          action_palette.provider = "telescope";
          chat.show_settings = false;
        };

        opts.log_level = "ERROR";
      };
    };

    extraPackages = [
      pkgs.claude-agent-acp
      pkgs.curl
    ];

    keymaps = [
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>aa";
        action = "<cmd>CodeCompanionActions<CR>";
        desc = "AI: action palette";
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>ac";
        action = "<cmd>CodeCompanionChat Toggle<CR>";
        desc = "AI: toggle chat";
      }
      {
        mode = "n";
        key = "<leader>ag";
        action = "<cmd>CodeCompanionChat adapter=gemini<CR>";
        desc = "AI: new chat (Gemini)";
      }
      {
        mode = "n";
        key = "<leader>al";
        action = "<cmd>CodeCompanionChat adapter=claude_code<CR>";
        desc = "AI: new chat (Claude Code)";
      }
      {
        mode = "v";
        key = "<leader>ad";
        action = "<cmd>CodeCompanionChat Add<CR>";
        desc = "AI: add selection to chat";
      }
      {
        mode = [
          "n"
          "v"
        ];
        key = "<leader>ai";
        action = ":CodeCompanion ";
        silent = false;
        desc = "AI: inline prompt";
      }
    ];
  };
}
