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
      lowPrioDef = lib.mapAttrsRecursiveCond (as: !lib.isDerivation as) (n: v: lib.mkOverride 1000 v) def;
    in
    {
      den.classes.config = { };
      den.classes.default = { };

      # Route and merge them directly into the standard OS classes
      den.classes.homeManager = lib.mkMerge [
        (lowPrioDef.homeManager or { })
        (cfg.homeManager or { })
      ];

      den.classes.nixos = lib.mkMerge [
        (lowPrioDef.nixos or { })
        (cfg.nixos or { })
      ];
    };
}
