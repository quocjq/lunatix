# eza — modern `ls` replacement. Flags/aliases live in the shell configs
# (bashrc for bash login shell, nushell aliases for the interactive shell);
# no own config file.
{ __findFile, ... }: {
  lix.eza = {
    os = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.eza ];
    };
  };
}
