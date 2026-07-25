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
      <lix/hyprland>
      <lix/greetd>
      <lix/stylix>
      <lix/lotus>
      <lix/yazi>
      <lix/zoxide>
      <lix/thunar>
      <lix/kanata>
      <lix/starship>
      <lix/bash>
      <lix/claude>
      <lix/git>
    ];
    user = { pkgs, ... }: {
      initialHashedPassword = "$6$.u5xmD5jRI69qFuA$L/M.0dWMo4pS5tLIsgZboyEzZeVXI.v17sG0SDv7WekS.VNEwyEbswld8yV3FHXymhUCnc1phCxyHxpi66uLs.";
      packages = with pkgs; [
        # codecrafters-cli
        just
        nh
        ghostty
        neovim
        wget
        curl
        obsidian
      ];
    };
  };
}
