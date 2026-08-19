{ __findFile, ... }: {
  lix.bat = {
    os = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        bat
      ] ++ (with pkgs.bat-extras; [
        batman
        batpipe
        batgrep
      ]);
    };
    maid = {
      file.xdg_config."bat/config".text = "--pager='less -FR'";
    };
  };
}
