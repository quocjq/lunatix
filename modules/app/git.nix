{
  lix.git = {
    secrets = [
      {
        name = "github-token";
        owner = "root";
        mode = "400";
      }
    ];
    os = { pkgs, config, ... }: {
      nix.extraOptions = ''
        !include ${config.age.secrets."github-token".path}
      '';
      # nix-maid has no package management; git + difftastic land in the
      # host environment instead.
      environment.systemPackages = with pkgs; [
        git
        difftastic
      ];
    };
    maid =
      { pkgs, ... }:
      let
        gitIni = pkgs.formats.gitIni {
          listsAsDuplicateKeys = true;
        };
      in
      {
        file.xdg_config."git/config" = {
          source = gitIni.generate "git-config" {
            user = {
              name = "Lunixose";
              email = "quocjq@gmail.com";
            };
            init.defaultBranch = "main";
            pull.rebase = false;
            pager.difftool = true;
            diff.tool = "difftastic";
            difftool.prompt = false;
            difftool.difftastic.cmd = "${pkgs.difftastic}/bin/difft $LOCAL $REMOTE";
            github.user = "quocjq";
            gitlab.user = "quocjq";
            core.editor = "emacs";
            # programs.delta (HM) → [delta] section of the same gitconfig.
            delta = {
              line-numbers = true;
              side-by-side = false;
            };
            # programs.git.lfs.enable (HM) → git-lfs filters.
            "filter.lfs" = {
              clean = "git-lfs clean -- %f";
              smudge = "git-lfs smudge -- %f";
              process = "git-lfs filter-process";
              required = true;
            };
            alias = {
              "dff" = "difftool";
              "fap" = "fetch --all -p";
              "rm-merged" =
                "for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D";
              "recents" =
                "for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'";
            };
          };
        };
        file.xdg_config."git/ignore".text = ''
          .DS_Store
          *.swp
          .direnv
          .envrc
          .envrc.local
          .env
          .env.local
          .jj
          devshell.toml
          .tool-versions
          /.github/chatmodes
          /.github/instructions
          *.key
          target
          result
          out
          old
          *~
          .aider*
          .crush*
          CRUSH.md
          GEMINI.md
          CLAUDE.md
          .workspaces
          .agents
          .claude
          AGENT*
          docs/superpowers
        '';
      };
  };
}
