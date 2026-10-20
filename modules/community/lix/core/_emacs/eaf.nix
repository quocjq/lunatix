{ inputs, ... }:
let
  apps = import ./_eaf/apps.nix;
in
{
  # EAF is vendored in ./_eaf rather than taken from nixpkgs, whose copies run
  # months behind upstream. Sources come from these inputs, so bumping a version
  # is `nix flake update eaf-browser` — see ./_eaf/version.nix for how the
  # melpaBuild version string is derived from the lock entry.
  #
  # `_eaf/` is skipped by import-tree (its default filter drops any path
  # containing `/_`), which is what keeps those plain derivation files from
  # being evaluated as flake-parts modules.
  flake-file.inputs = {
    eaf = {
      url = "github:emacs-eaf/emacs-application-framework";
      flake = false;
    };
    eaf-browser = {
      url = "github:emacs-eaf/eaf-browser";
      flake = false;
    };
    eaf-pdf-viewer = {
      url = "github:emacs-eaf/eaf-pdf-viewer";
      flake = false;
    };
    eaf-file-manager = {
      url = "github:emacs-eaf/eaf-file-manager";
      flake = false;
    };
    eaf-image-viewer = {
      url = "github:emacs-eaf/eaf-image-viewer";
      flake = false;
    };
  };

  # Iteration target: `nix build .#eaf`. Built against the plain nixpkgs emacs,
  # so it is only good for settling npm hashes and catching upstream patch drift
  # without paying for a home-manager rebuild.
  #
  # nixpkgs is imported here rather than using the perSystem `pkgs`, because
  # that one is bound in modules/flake/devshell.nix with no overlays — and
  # without ./_eaf/overlay.nix the shared python env fails to build.
  perSystem =
    { system, ... }:
    {
      packages.eaf =
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ (import ./_eaf/overlay.nix) ];
          };
          s = import ./_eaf/scope.nix {
            inherit inputs pkgs;
            epkgs = pkgs.emacsPackages;
          };
        in
        s.withApplications (apps s);
    };
}
