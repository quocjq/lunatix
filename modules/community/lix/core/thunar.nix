{ ... }:
{
  lix.thunar = {
    provides.to-hosts.nixos =
      { pkgs, ... }:
      {
        programs.thunar = {
          enable = true;
          plugins = with pkgs; [
            thunar-archive-plugin
            thunar-volman
          ];
        };
        services.gvfs.enable = true;
        # nix-maid has no package management; thumbnailers moved from
        # home-manager's home.packages to the host environment.
        environment.systemPackages = with pkgs; [
          tumbler
          ffmpegthumbnailer
          poppler-utils
          ffmpeg
          gvfs
        ];
      };
  };
}
