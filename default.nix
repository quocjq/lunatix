# default.nix — Den no-flake entry point (vix unflake pattern)
#
# - sources: pins loaded from npins/sources.json
# - follows: pin-to-pin follows loaded from follows.nix
# - with-inputs: small lib that assembles an `inputs` attrset from sources + follows
# - outputs: flake-parts.lib.mkFlake using the assembled inputs + import-tree
#
# Run `nix-build -A flake.nixosConfigurations.igloo.config.system.build.toplevel`
# or `nix build .#igloo` (flake.nix is a thin shim around this file).
#
# To update pins: edit modules/flake/dendritic.nix (or any module's
# flake-file.inputs.X.url), then `nix run .#write-npins`.
let
  sources = import ./npins;
  follows = import ./follows.nix;
  with-inputs = import sources.with-inputs sources follows;
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
      (inputs.import-tree ./modules);
in with-inputs outputs
