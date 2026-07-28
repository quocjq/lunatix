{
  lix.hyprland.homeManager =
    { pkgs, ... }:
    {
      # home.file.".local/bin/type-submap-watcher" = {
      #   source = ../scripts/type-submap-watcher.sh;
      #   executable = true;
      # };
      # home.packages = [
      #   pkgs.wtype # Hyprland .socket2 stream consumer
      #   pkgs.jq # parses the JSON workspace event payload
      # ];
    };
}
