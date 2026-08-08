# tools — shells, prompt, file managers, browser.
{ __findFile, ... }: {
  lix.tools = {
    includes = [
      <lix/bash>
      <lix/bat>
      <lix/btop>
      <lix/nushell>
      <lix/eza>
      <lix/easyeffects>
      <lix/flameshot>
      <lix/fzf>
      <lix/starship>
      <lix/sioyek>
      <lix/yazi>
      <lix/zoxide>
      <lix/thunar>
      <lix/mpv>
      <lix/zenwser>
    ];
  };
}