{
  lix.yazi = {
    os = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.yazi ];
    };
    maid = {
    };
  };
}
