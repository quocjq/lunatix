{
  lix.claude = {
    homeManager = { pkgs, ... }: {
      programs.claude-code = {
        enable = true;
        # Preserve the theme that was in the hand-written ~/.claude/settings.json
        # before home-manager took over the file.
        settings.theme = "dark";
        settings.statusLine = {
          type = "command";
          command = "${pkgs.starship}/bin/starship statusline claude-code";
          padding = 0;
        };
        plugins = with pkgs; [
          (fetchFromGitHub {
            owner = "juliusbrussee";
            repo = "caveman";
            rev = "0d95a81d35a9f2d123a5e9430d1cfc43d55f1bb0";
            sha256 = "sha256-VqRHx3/4SSCnEh3cUJ/he5saIfwNhS0hOzoH/wwtU2o=";
          })
        ];
      };
    };
  };
}
