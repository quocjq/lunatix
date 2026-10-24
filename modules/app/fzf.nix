# fzf — general-purpose command-line fuzzy finder.
{ __findFile, ... }: {
  lix.fzf = {
    os = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.fzf ];
    };
    maid = {
      # nushell reads env; FZF_DEFAULT_OPTS lands in config.nu via env.nu.
      file.xdg_config."nushell/env.nu".text =
        "$env.FZF_DEFAULT_OPTS = \"--margin=1 --layout=reverse --border=none --info='hidden' --header=''\""
        + " + \" --prompt='/ ' -i --no-bold --bind='enter:execute(nvim {})'\""
        + " + \" --preview='bat --style=numbers --color=always --line-range :500 {}'\""
        + " + \" --preview-window=right:60%:wrap --color=bg+:-1,bg:-1\"";
    };
  };
}
