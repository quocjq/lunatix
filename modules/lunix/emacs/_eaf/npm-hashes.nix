# `fetchNpmDeps` output hashes. These are content hashes over each app's
# `package-lock.json`, so they are NOT refreshed by `nix flake update` — after
# bumping an input, rebuild and copy the hash Nix reports here.
#
# Bootstrap/refresh a single entry with either:
#   nix build .#eaf            # read the expected hash out of the failure
#   nix run nixpkgs#prefetch-npm-deps -- <input-store-path>/package-lock.json
#
# `eaf` (the framework) and `eaf-pdf-viewer` ship no package.json and are absent
# here by design.
{
  eaf-browser = "sha256-uycqjl6y9daIBkMRwrkRnHumNMs+Ahi2aooZOeMTRsY=";
  eaf-file-manager = "sha256-dzfw+CgoM1CulPoa0KEzUX9dlBiquX4BkYNwU3vMb+Q=";
  eaf-image-viewer = "sha256-d1DVOAhYtXEzRQcUWFJE0gbHnqPRCUGibSqc/Nf3dVE=";
}
