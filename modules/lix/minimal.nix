{__findFile, ...}: {
  lix.minimal = {
    includes = [
      <lix/hyprland>
      <lix/greetd>
      <lix/zenwser>
      <lix/bash>
      <lix/nushell>
      <lix/starship>
      <lix/doomacs>
    ];

    os = {pkgs, ...}: {
      environment.systemPackages = with pkgs; [
        ghostty
        neovim
      ];
    };
    maid = {};
  };
}
