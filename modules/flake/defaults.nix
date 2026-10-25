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
        config = final.config // {rewriteURL = url: url;};
      };
    })
  ];
  den.schema.host.includes = [den.aspects.stable-packages];
}
