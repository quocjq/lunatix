# Ships the submap-gating daemon into ~/.local/bin and adds the socket
# tool it depends on. Auto-loaded by flake-parts via import-tree.
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
