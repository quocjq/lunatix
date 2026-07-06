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
      plasma
      printing
      ssh
      x11
    ];
  };
}
