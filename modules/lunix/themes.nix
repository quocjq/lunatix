{ ... }:
{
  lix.themes = {
    os = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        papirus-icon-theme
      ];
      environment.variables = {
        XCURSOR_THEME = "breeze_cursors";
        XCURSOR_SIZE = "24";
      };
      xdg.icons.enable = true;
    };

    provides.to-hosts.homeManager = { pkgs, ... }: {
      home.pointerCursor = {
        enable = true;
        gtk.enable = true;
        x11.enable = true;
        name = "breeze_cursors";
        package = pkgs.kdePackages.breeze;
        size = 24;
      };
    };
  };
}
