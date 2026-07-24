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
      };
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          tumbler
          ffmpegthumbnailer
          poppler-utils
          ffmpeg
          gvfs
        ];
      };
  };
}
