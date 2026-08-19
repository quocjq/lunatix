{
  lix.zoxide = {
    os = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.zoxide ];
    };
    maid = {
      # nushell integration folded into config.nu by lix.nushell;
      # the bash login hook is added by lix.bash.
    };
  };
}
