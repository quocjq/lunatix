{ __findFile, ... }: {
  lix.mpv = {
    homeManager = {
      programs.mpv.enable = true;
    };
  };
}