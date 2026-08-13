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

    # terminal + neovim: not standalone aspects (ghostty lives in the user
    # packages, neovim too) — provide them here so minimal is self-contained.
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        ghostty # terminal
        neovim # editor
      ];
      programs.ghostty.enable = true;
    };
  };
}
