# development — editor, CLI assistants, VCS.
{ __findFile, ... }: {
  lix.development = {
    includes = [
      <lix/doomacs>
      <lix/git>
    ];
  };
}