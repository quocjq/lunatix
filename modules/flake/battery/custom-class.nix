{
  lib,
  config,
  ...
}:
{
  den.batteries.custom-class =
    let
      cfg = config.den.classes.config or { };
      def = config.den.classes.default or { };
      highPrioCfg = lib.mapAttrsRecursiveCond (as: !lib.isDerivation as) (n: v: lib.mkOverride 75 v) cfg;
    in
    {
      den.classes.config = { };
      den.classes.default = { };

      # Route and merge them directly into the standard OS classes
      den.classes.homeManager = lib.mkMerge [
        (highPrioCfg.homeManager or { })
        (def.homeManager or { })
      ];

      den.classes.nixos = lib.mkMerge [
        (highPrioCfg.nixos or { })
        (def.nixos or { })
      ];
    };
}
