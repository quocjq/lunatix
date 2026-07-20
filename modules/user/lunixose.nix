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
    ];
    user = { pkgs, ... }: {
      initialHashedPassword = "$6$.u5xmD5jRI69qFuA$L/M.0dWMo4pS5tLIsgZboyEzZeVXI.v17sG0SDv7WekS.VNEwyEbswld8yV3FHXymhUCnc1phCxyHxpi66uLs.";
      packages = with pkgs; [
        codecrafters-cli
        yazi
        ghostty
        neovim
        wget
        git
        curl
        obsidian
      ];
    };
  };
}
