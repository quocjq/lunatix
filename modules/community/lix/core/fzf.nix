# fzf — general-purpose command-line fuzzy finder.
{ __findFile, ... }: {
  lix.fzf = {
    homeManager = { lib, ... }: {
      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
        colors = lib.mkForce {
          "bg+" = "-1";
          "bg" = "-1";
        };
        defaultOptions = [
          "--margin=1"
          "--layout=reverse"
          "--border=none"
          "--info='hidden'"
          "--header=''"
          "--prompt='/ '"
          "-i"
          "--no-bold"
          "--bind='enter:execute(nvim {})'"
          "--preview='bat --style=numbers --color=always --line-range :500 {}'"
          "--preview-window=right:60%:wrap"
        ];
      };
    };
  };
}