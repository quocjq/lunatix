# minimal — the core daily-use desktop: WM, DM, browser, terminal, shell,
# editors. A curated subset of lix.* for a lean install (reinstall.sh's
# "minimal" option). Everything here is expected on every desktop host.
{ __findFile, ... }: {
  lix.minimal = {
    includes = [
      # WM + DM
      <lix/hyprland>
      <lix/greetd>
      # browser
      <lix/zenwser>
      # shell + prompt
      <lix/bash>
      <lix/nushell>
      <lix/starship>
      # editor
      <lix/doomacs>
    ];

    # terminal + neovim: nix-maid has no package management, so these land in
    # the host environment (mirrors the old home.packages set).
    os = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        ghostty # terminal
        neovim # editor
      ];
    };
    maid = { };
  };
}
