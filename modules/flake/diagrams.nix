# Build Mermaid diagrams of den's aspect-resolution graph for every host
# declared in `den.hosts`, plus a fleet-wide Sankey. Wired as flake
# `packages.diag-<host>` and `packages.diag-fleet`.
#
# API surface (`den.lib.capture`, `inputs.den-diagram.lib.context`,
# `toMermaid`, `captureFleet`, `toFleetSankeyMermaid`) follows
# https://den.denful.dev/reference/diag. If a future input revision drifts
# the call shape, inspect with:
#   nix eval .#inputs.den-diagram.lib --apply 'lib: builtins.attrNames lib'
{ inputs, den, lib, ... }:
let
  diagram = inputs.den-diagram.lib;

  # Walk every arch in `den.hosts.<arch>` and flatten to host entities.
  allHosts = lib.concatMap builtins.attrValues (builtins.attrValues den.hosts);

  buildHost =
    pkgs: host:
    let
      captured = den.lib.capture.captureWithPathsWith {
        classes = [
          "nixos"
          "homeManager"
          "user"
        ];
        root = den.lib.resolveEntity "host" { inherit host; };
        ctx = { inherit host; };
      };
      graph = diagram.context {
        inherit (captured) entries ctxTrace;
        name = host.name;
      };
    in
    pkgs.writeText "diag-${host.name}.mmd" (diagram.toMermaid graph);

  buildFleet =
    pkgs:
    pkgs.writeText "diag-fleet.mmd" (
      diagram.toFleetSankeyMermaid (den.lib.capture.captureFleet { inherit (den) hosts; })
    );
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        diag-fleet = buildFleet pkgs;
      }
      // lib.foldl' (acc: host: acc // { "diag-${host.name}" = buildHost pkgs host; }) { } allHosts;
    };
}
