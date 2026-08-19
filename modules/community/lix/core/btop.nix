{ __findFile, ... }: {
  lix.btop = {
    os = { pkgs, ... }: {
      environment.systemPackages = [
        (pkgs.btop.override {
          rocmSupport = true;
          cudaSupport = true;
        })
      ];
    };
    maid = {
      file.xdg_config."btop/btop.conf".source = ./_config/.config/btop/btop.conf;
      file.xdg_config."btop/themes".source = ./_config/.config/btop/themes;
    };
  };
}
