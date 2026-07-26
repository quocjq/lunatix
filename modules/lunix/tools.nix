# tools — shells, prompt, file managers, browser.
{ __findFile, ... }: {
  lix.tools = {
    includes = [
      <lix/bash>
      <lix/nushell>
      <lix/starship>
      <lix/yazi>
      <lix/zoxide>
      <lix/thunar>
      <lix/zenwser>
    ];
  };
}