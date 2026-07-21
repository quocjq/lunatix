{
  __findFile,
  ...
}:
{
  den.aspects.lunixose = {
    includes = [
      <den/define-user>
      <den/primary-user>
      <lix/doomacs>
      <lix/zenwser>
      <lix/nixcord>
      <lix/plasma>
      <lix/hyprland>
      <lix/kanata>
      <lix/starship>
      <lix/bash>
      <lix/claude>
      <lix/git>
    ];
    user = { pkgs, ... }: {
      initialHashedPassword = "$6$.u5xmD5jRI69qFuA$L/M.0dWMo4pS5tLIsgZboyEzZeVXI.v17sG0SDv7WekS.VNEwyEbswld8yV3FHXymhUCnc1phCxyHxpi66uLs.";
      packages = with pkgs; [
        claude-code
        codecrafters-cli
        just
        nh
        yazi
        ghostty
        neovim
        wget
        curl
        obsidian
      ];
    };
  };
}
