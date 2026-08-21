{ __findFile, ... }: {
  lix.mpv = {
    os = { pkgs, ... }: {
      environment.systemPackages = [
        pkgs.mpv-unwrapped
      ];
    };
  };
}
