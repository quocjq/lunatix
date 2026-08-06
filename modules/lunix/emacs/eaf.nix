{ inputs, ... }:
let
  apps =
    s: with s; [
      eaf-browser
      eaf-pdf-viewer
      eaf-file-manager
      eaf-image-viewer
    ];
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
  # NOT doom's, so it is only good for settling npm hashes and catching upstream
  # patch drift without paying for a home-manager rebuild.
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

  lix.doomacs = {
    # `extraPackages` is evaluated by `nix-doom-emacs-unstraightened` with the
    # epkgs built from `programs.doom-emacs.emacs` (the plum-py-overlaid
    # `pkgs.emacs` set in ./emacs.nix), so the composite here is built against
    # the same Python env the rest of the doom profile uses.
    homeManager =
      { pkgs, ... }:
      {
        programs.doom-emacs.extraPackages =
          epkgs:
          let
            s = import ./_eaf/scope.nix { inherit inputs pkgs epkgs; };
          in
          [ (s.withApplications (apps s)) ];
      };
  };
}
