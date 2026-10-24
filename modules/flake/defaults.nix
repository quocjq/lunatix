{
  inputs,
  lib,
  den,
  ...
}: {
  den.default.nixos.system.stateVersion = "26.05";
  den.default.includes = [
    den.aspects.settings
    den.batteries.hostname
  ];
  den.default.nixos.programs.bash.enable = true;
  den.schema.user.classes = lib.mkDefault [
    "maid"
  ];
  den.aspects.stable-packages.os.nixpkgs.overlays = [
    (final: _prev: {
      stable = import inputs.nixpkgs-stable {
        inherit (final.stdenv.hostPlatform) system;
        inherit (final) config;
      };
    })
  ];
  den.schema.host.includes = [den.aspects.stable-packages];
}
