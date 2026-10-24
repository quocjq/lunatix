{
  inputs,
  lib,
  ...
}: let
  configRoot = ./..;
in {
  flake-file.inputs = {
    nvf = {
      url = "github:NotAShelf/nvf";
      # FIXME: syntax highlighting not working with recent nixpkgs nvim treesiter packages
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  lix.nvf = {
    os = {pkgs, ...}: {
      imports = [inputs.nvf.nixosModules.default];
      environment.systemPackages = with pkgs; [
        neovim
      ];
      programs.nvf = {
        enable = true;
        settings.vim = {
          viAlias = true;
          vimAlias = true;
          debugMode = {
            enable = false;
            level = 16;
            logFile = "/tmp/nvim.log";
          };

          # vim.opts and vim.options are aliased
          opts = {
            expandtab = true;
          };

          clipboard = {
            enable = true;
            registers = "unnamedplus";
            providers = {
              # Wayland (Hyprland, Sway, GNOME/KDE Wayland)
              wl-copy.enable = pkgs.stdenv.hostPlatform.isLinux;
              # X11 / XWayland
              xclip.enable = pkgs.stdenv.hostPlatform.isLinux;
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
            {
              mode = "n";
              key = "<leader>.";
              action = "<cmd>Telescope find_files<CR>";
              desc = "Search for files in telescope";
            }
            {
              mode = "n";
              key = "-";
              action = "<cmd>Oil<CR>";
              desc = "Open parent dir";
            }
          ];

          spellcheck = {
            enable = true;
            programmingWordlist.enable = true;
          };

          lsp = {
            # This must be enabled for the language modules to hook into
            # the LSP API.
            enable = true;

            formatOnSave = true;
            lspkind.enable = false;
            lightbulb.enable = true;
            lspsaga.enable = false;
            trouble.enable = true;
            lspSignature.enable = false; # conflicts with blink in maximal
            nvim-docs-view.enable = true;
            presets.harper.enable = true;
            servers = {
              nil.settings.nil = {
                formatting.command = ["alejandra"];
              };
              nixd.settings.nixd = {
                nixpkgs.expr = "import (builtins.getFlake (builtins.toString ./.)).inputs.nixpkgs { }";
                formatting.command = "alejandra";
                options = {
                  nixos.expr = ''(builtins.getFlake ${configRoot}).nixosConfigurations.nixos-pc.options'';
                };
              };
            };
            otter-nvim = {
              enable = true;
              setupOpts.buffers.write_to_disk = true;
            };
          };

          debugger = {
            nvim-dap = {
              enable = true;
              ui.enable = true;
            };
          };
          lazy.plugins = {
            "nvim-navic" = {
              enabled = true;
              package = pkgs.vimPlugins.nvim-navic;
              # You can add events here, such as: event = [ "LspAttach" ];
            };

            "blink.cmp" = {
              enabled = true;
              event = ["InsertEnter"];
              package = pkgs.vimPlugins.blink-cmp;
              setupModule = "blink.cmp";
              setupOpts = {
                sources.default = ["lsp" "path" "snippets" "buffer"];
                snippets.preset = "luasnip";
              };
            };
          };

          languages = {
            enableFormat = true;
            enableTreesitter = true;
            enableExtraDiagnostics = true;

            # Languages that will be supported in default and maximal configurations.
            nix = {
              enable = true;
              lsp.enable = true;
              lsp.servers = ["nixd" "nil"];
              treesitter.enable = true;
            };
            markdown.enable = true;

            # Languages that are enabled in the maximal configuration.
            bash.enable = true;
            clang.enable = true;
            cmake.enable = true;
            css.enable = true;
            scss.enable = true;
            html.enable = true;
            json.enable = true;
            sql.enable = false;
            java.enable = true;
            kotlin.enable = false;
            typescript.enable = true;
            go.enable = false;
            lua.enable = true;
            zig.enable = false;
            python = {
              enable = true;
              lsp.servers = ["pyright"];
            };
            typst.enable = true;
            rust = {
              enable = true;
              # Can only be enabled if lsp.enable = false
              extensions.rustaceanvim.enable = false;
              extensions.crates-nvim.enable = true;
            };
            toml.enable = true;
            xml.enable = true;
            tex.enable = true;
            docker.enable = true;
            env.enable = true;

            # Language modules that are not as common.
            arduino.enable = false;
            assembly.enable = false;
            astro.enable = false;
            awk.enable = false;
            beancount.enable = false;
            csharp.enable = false;
            dart.enable = false;
            elixir.enable = false;
            fish.enable = false;
            fluent.enable = false;
            fsharp.enable = false;
            gettext.enable = false;
            gleam.enable = false;
            glsl.enable = false;
            haskell.enable = false;
            hcl.enable = false;
            jinja.enable = false;
            jq.enable = false;
            julia.enable = false;
            just.enable = false;
            liquid.enable = false;
            lisp.enable = false;
            make.enable = false;
            nu.enable = false;
            ocaml.enable = false;
            openscad.enable = false;
            pug.enable = false;
            qml.enable = false;
            r.enable = false;
            ruby.enable = false;
            scala.enable = false;
            standard-ml.enable = false;
            svelte.enable = false;
            tera.enable = false;
            tsx.enable = false;
            twig.enable = false;
            vala.enable = false;
            vue.enable = false;
            http.enable = false;
            powershell.enable = false;
            protobuf.enable = false;
            zsh.enable = false;

            # Nim LSP is broken on Darwin and therefore
            # should be disabled by default. Users may still enable
            # `vim.languages.nim` to enable it, this does not restrict
            # that.
            # See: <https://github.com/PMunch/nimlsp/issues/178#issue-2128106096>
            nim.enable = false;
          };

          visuals = {
            nvim-scrollbar.enable = true;
            neoscroll-nvim.enable = false;
            twilight-nvim.enable = false;
            satellite-nvim.enable = false;
            nvim-web-devicons.enable = true;
            nvim-cursorline.enable = true;
            cinnamon-nvim.enable = true;
            fidget-nvim.enable = true;

            highlight-undo.enable = true;
            blink-indent.enable = false;
            indent-blankline.enable = true;

            # Fun
            cellular-automaton.enable = false;
          };

          statusline = {
            lualine = {
              enable = true;
              integrations.breadcrumbs = {
                vanilla.enable = true;
                nvim-navic.enable = lib.mkForce false;
                navbuddy.enable = true;
                lspsaga.enable = false;
              };
            };
          };

          theme = {
            enable = true;
            name = lib.mkDefault "catppuccin";
            style = "mocha";
            transparent = true;
          };

          autopairs.nvim-autopairs.enable = true;

          # nvf provides various autocomplete options. The tried and tested nvim-cmp
          # is enabled in default package, because it does not trigger a build. We
          # enable blink-cmp in maximal because it needs to build its rust fuzzy
          # matcher library.
          autocomplete = {
            nvim-cmp.enable = true;
            blink-cmp.enable = false;
          };
          snippets.luasnip.enable = true;

          tabline = {
            nvimBufferline.enable = false;
          };

          treesitter = {
            enable = true;
            textobjects.enable = true;
            context.enable = false;
            fold = false;
            highlight.enable = true;
            grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
              nu
              kdl
              rnoweb
              yaml
              markdown
              markdown_inline
              r
              hyprlang
              toml
            ];
          };

          binds = {
            whichKey.enable = true;
            cheatsheet.enable = true;
          };

          telescope.enable = true;

          git = {
            enable = true;
            gitsigns.enable = true;
            gitsigns.codeActions.enable = false; # throws an annoying debug message
            neogit.enable = true;
          };

          minimap = {
            minimap-vim.enable = false;
          };

          dashboard = {
            dashboard-nvim.enable = true;
            alpha.enable = false;
          };

          notify = {
            nvim-notify.enable = true;
          };

          projects = {
            project-nvim.enable = true;
          };

          utility = {
            ccc.enable = false;
            smart-paste-nvim.enable = true;
            guess-indent-nvim.enable = true;
            auto-indent-nvim.enable = true;
            vim-wakatime.enable = false;
            diffview-nvim.enable = true;
            yanky-nvim.enable = false;
            qmk-nvim.enable = false; # requires hardware specific options
            icon-picker.enable = true;
            surround.enable = true;
            leetcode-nvim.enable = true;
            multicursors.enable = true;
            smart-splits.enable = true;
            undotree.enable = true;
            nvim-biscuits.enable = true;
            grug-far-nvim.enable = true;
            oil-nvim = {
              enable = true;
              gitStatus.enable = true;
              setupOpts = {
                default_file_explorer = true;
                delete_to_trash = true;
                skip_confirm_for_simple_edits = true;

                view_options = {
                  show_hidden = true;
                  natural_order = true;
                };
              };
            };

            motion = {
              hop.enable = true;
              leap.enable = true;
              precognition.enable = true;
            };
            images = {
              image-nvim.enable = false;
              img-clip.enable = true;
            };
          };

          notes = {
            neorg.enable = false;
            orgmode.enable = false;
            todo-comments.enable = true;
          };

          terminal = {
            toggleterm = {
              enable = true;
              lazygit.enable = true;
            };
          };

          ui = {
            borders.enable = true;
            dropbar-nvim.enable = false;
            noice.enable = true;
            colorizer.enable = true;
            modes-nvim.enable = false; # the theme looks terrible with catppuccin
            illuminate.enable = true;
            smartcolumn = {
              enable = true;
              setupOpts.custom_colorcolumn = {
                # this is a freeform module, it's `buftype = int;` for configuring column position
                nix = "110";
                ruby = "120";
                java = "130";
                go = ["90" "130"];
              };
            };
            fastaction.enable = true;
          };

          assistant = {
            chatgpt.enable = false;
            copilot = {
              enable = false;
              cmp.enable = true;
            };
            codecompanion-nvim.enable = false;
            avante-nvim.enable = false;
          };

          session = {
            nvim-session-manager.enable = false;
          };

          gestures = {
            gesture-nvim.enable = false;
          };

          comments = {
            comment-nvim.enable = true;
          };

          presence = {
            neocord.enable = false;
            cord-nvim.enable = false;
          };
        };
      };
    };
  };
}
