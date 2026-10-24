{__findFile, ...}: {
  lix.btop = {
    os = {pkgs, ...}: {
      environment.systemPackages = [
        (pkgs.btop.override {
          rocmSupport = true;
          cudaSupport = true;
        })
      ];
    };
    maid = {
      file.xdg_config."btop/btop.conf".source = "{{home}}/config/btop/btop.conf";
      file.xdg_config."btop/themes".source = "{{home}}/config/btop/themes";
    };
  };
}
