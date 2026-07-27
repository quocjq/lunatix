{
  lix.nushell = {
    provides = {
      zoxide.homeManager.programs.zoxide.enableNushellIntegration = true;
      eza.homeManager.programs.eza.enableNushellIntegration = true;
      yazi.homeManager.programs.yazi.enableNushellIntegration = true;
      starship.homeManager.programs.starship.enableNushellIntegration = true;
    };
    homeManager = {
      programs.nushell = {
        enable = true;
        settings = {
          show_banner = false;
          completions.external = {
            enable = true;
            max_results = 200;
          };
          history = {
            file_format = "sqlite";
            sync_on_enter = true;
            isolation = true;
          };
          buffer_editor = [
            "emacsclient"
            "-a"
            "-t"
          ];
        };
        shellAliases = {
          ls = "eza";
          lt = "eza --tree --level=2";
          ll = "eza  -lh --no-user --long";
          la = "eza -lah ";
          tree = "eza --tree ";
          g = "git";
          e = "nvim";
        };
        extraConfig = ''
          load-env (
          open '/home/lunixose/.config/secrets/env'
          | str trim
          | lines
          | parse 'export {name}="{value}"'
          | transpose --header-row --as-record
          )

          def --env claudem3 [...args: string] {
             if ($env.MINIMAX_API_KEY? == null) {
               error make {msg: "MINIMAX_API_KEY is not set. Please add it to secret env"}
             }
             with-env {
               ANTHROPIC_BASE_URL: "https://api.minimax.io/anthropic"
               ANTHROPIC_AUTH_TOKEN: $env.MINIMAX_API_KEY
               API_TIMEOUT_MS: "3000000"
               CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: "1"
               ANTHROPIC_MODEL: "MiniMax-M3"
               ANTHROPIC_SMALL_FAST_MODEL: "MiniMax-M3"
               ANTHROPIC_DEFAULT_SONNET_MODEL: "MiniMax-M3"
               ANTHROPIC_DEFAULT_OPUS_MODEL: "MiniMax-M3"
               ANTHROPIC_DEFAULT_HAIKU_MODEL: "MiniMax-M3"
             } {
               ^claude ...$args
             }
           }

           def --env clauded [...args: string] {
             if ($env.MY_ANTHROPIC_API_KEY? == null) {
               error make {msg: "MY_ANTHROPIC_API_KEY is not set. Please add it to secret env"}
             }
             with-env {
               ANTHROPIC_AUTH_TOKEN: $env.MY_ANTHROPIC_API_KEY
               ANTHROPIC_BASE_URL: "https://agentrouter.org"
               ANTHROPIC_MODEL: "claude-opus-4-8"
               ANTHROPIC_SMALL_FAST_MODEL: "claude-opus-4-8"
               ANTHROPIC_DEFAULT_SONNET_MODEL: "claude-opus-4-8"
               ANTHROPIC_DEFAULT_OPUS_MODEL: "claude-opus-4-8"
               ANTHROPIC_DEFAULT_HAIKU_MODEL: "claude-opus-4-8"
             } {
               ^claude ...$args
             }
           }

           # DEVENV
           $env._DEVENV_HOOK_UNTRUSTED = ""

           $env.config = ($env.config | upsert hooks.env_change.PWD (
               ($env.config | get -o hooks.env_change.PWD | default []) | append {||
                   # Inside devenv shell: exit when leaving the project directory
                   if ("DEVENV_ROOT" in $env) {
                       if not ($env.PWD == $env.DEVENV_ROOT or ($env.PWD | str starts-with ($env.DEVENV_ROOT + "/"))) {
                           # Save target directory so the parent shell can cd there after exit
                           $env.PWD | save --force ($env.DEVENV_ROOT + "/.devenv/exit-dir")
                           exit
                       }
                       return
                   }

                   let result = (^devenv hook-should-activate | complete)

                   if ($result.stderr | str trim) != "" {
                       print -e $result.stderr
                   }

                   if $result.exit_code == 0 {
                       let dir = ($result.stdout | str trim)
                       if $dir != "" {
                           do { cd $dir; ^devenv shell }
                           $env._DEVENV_HOOK_UNTRUSTED = ""
                           # If the devenv shell exited due to cd outside the project, follow the user there
                           let exit_dir_file = ($dir + "/.devenv/exit-dir")
                           if ($exit_dir_file | path exists) {
                               let target_dir = (open $exit_dir_file | str trim)
                               rm -f $exit_dir_file
                               if ($target_dir | path exists) {
                                   cd $target_dir
                               }
                           }
                       } else {
                           $env._DEVENV_HOOK_UNTRUSTED = ""
                       }
                   } else {
                       $env._DEVENV_HOOK_UNTRUSTED = $env.PWD
                   }
               }
           ))

           # Retry activation on each prompt for untrusted directories (after 'devenv allow')
           $env.config = ($env.config | upsert hooks.pre_prompt (
               ($env.config | get -o hooks.pre_prompt | default []) | append {||
                   let untrusted = ($env | get -o _DEVENV_HOOK_UNTRUSTED | default "")
                   if $untrusted == "" {
                       return
                   }
                   if ("DEVENV_ROOT" in $env) {
                       return
                   }

                   let result = (^devenv hook-should-activate | complete)

                   if $result.exit_code == 0 {
                       let dir = ($result.stdout | str trim)
                       if $dir != "" {
                           do { cd $dir; ^devenv shell }
                           $env._DEVENV_HOOK_UNTRUSTED = ""
                           # If the devenv shell exited due to cd outside the project, follow the user there
                           let exit_dir_file = ($dir + "/.devenv/exit-dir")
                           if ($exit_dir_file | path exists) {
                               let target_dir = (open $exit_dir_file | str trim)
                               rm -f $exit_dir_file
                               if ($target_dir | path exists) {
                                   cd $target_dir
                               }
                           }
                       }
                   }
               }
           ))
        '';
      };
    };
  };
}
