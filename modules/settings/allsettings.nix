{ den, ... }:
{
  den.aspects.settings = {
    includes = with den.aspects; [
      audio
      bluetooth
      fonts
      locale
      network
      nix-settings
      printing
      ssh
      x11
    ];
  };
}
