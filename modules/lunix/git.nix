{
  lix.git = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.difftastic ];
        programs.git = {
          enable = true;
          signing.format = "ssh";
          settings = {
            user.name = "Lunixose";
            user.email = "quocjq@gmail.com";
            init.defaultBranch = "main";
            pull.rebase = false;
            pager.difftool = true;
            diff.tool = "difftastic";
            difftool.prompt = false;
            difftool.difftastic.cmd = "${pkgs.difftastic}/bin/difft $LOCAL $REMOTE";
            github.user = "quocjq";
            gitlab.user = "quocjq";
            core.editor = "emacs";
            alias = {
              "dff" = "difftool";
              "fap" = "fetch --all -p";
              "rm-merged" =
                "for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D";
              "recents" =
                "for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'";
            };
          };
          ignores = [
            ".DS_Store"
            "*.swp"
            ".direnv"
            ".envrc"
            ".envrc.local"
            ".env"
            ".env.local"
            ".jj"
            "devshell.toml"
            ".tool-versions"
            "/.github/chatmodes"
            "/.github/instructions"
            "*.key"
            "target"
            "result"
            "out"
            "old"
            "*~"
            ".aider*"
            ".crush*"
            "CRUSH.md"
            "GEMINI.md"
            "CLAUDE.md"
            ".workspaces"
            ".agents"
            ".claude"
            "AGENT*"
            "docs/superpowers"
          ];
          includes = [ ];
          lfs.enable = true;
        };

        programs.delta.enable = true;
        programs.delta.options = {
          line-numbers = true;
          side-by-side = false;
        };
      };
  };
}
