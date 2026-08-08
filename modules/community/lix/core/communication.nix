# communication — chat/messaging clients.
{ __findFile, ... }: {
  lix.communication = {
    includes = [
      <lix/nixcord>
    ];
  };
}