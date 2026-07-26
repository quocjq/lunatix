# system — compositor, theming, login manager, input plumbing.
# `lix.hyprland` already pulls in `lix.noctalia` via its own includes
# (see modules/lunix/hyprland/hyprland.nix:14-16) — no need to list
# noctalia here.
{
  lix.system = {
    includes = [
      <lix/hyprland>
      <lix/stylix>
      <lix/greetd>
      <lix/kanata>
      <lix/lotus>
    ];
  };
}