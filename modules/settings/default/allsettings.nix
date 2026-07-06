{ den, ... }:
{
  den.aspects.settings = {
    includes = with den.aspects; [
      audio
      bluetooth
      fonts
      local
      network
      nix-settings
      printing
      ssh
      x11
    ];
  };
}
