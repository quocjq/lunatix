# Version string for a `flake = false` input, in the format nixpkgs' melpaBuild
# expects.
#
# `melpaBuild` matches `^.*-unstable-([0-9]{4})-([0-9]{2})-([0-9]{2})$` against
# `version` and turns it into `melpaVersion` (e.g. "20260525.0"), which the
# derivations interpolate into `$LISPDIR`. A version that does not match is
# passed through verbatim and would produce a different directory name than the
# framework's `app/` copy expects, so keep this shape.
#
# `lastModifiedDate` is the commit time of the locked rev, so bumping an input
# bumps the version with no manual edit.
input:
let
  d = input.lastModifiedDate;
in
"0-unstable-${builtins.substring 0 4 d}-${builtins.substring 4 2 d}-${builtins.substring 6 2 d}"
