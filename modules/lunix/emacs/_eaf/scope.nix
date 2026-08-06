# Builds the vendored EAF derivations against a caller-supplied emacs package
# set and re-exposes nixpkgs' `eaf.withApplications` API.
#
# `epkgs` is passed in rather than taken from `pkgs` because the real consumer
# is `programs.doom-emacs.extraPackages`, which is evaluated against doom's own
# scope (`emacsPackagesFor` of the emacs configured in ../emacs.nix). Building
# there means elisp deps such as `all-the-icons` resolve to doom's pinned
# versions instead of a second, conflicting copy.
{
  inputs,
  pkgs,
  epkgs,
}:
let
  mkVersion = import ./version.nix;
  npmHashes = import ./npm-hashes.nix;

  call =
    file: input: extra:
    epkgs.callPackage file (
      {
        src = input;
        version = mkVersion input;
      }
      // extra
    );

  eaf-browser = call ./browser.nix inputs.eaf-browser {
    # Shadow fix: inside the emacs scope `aria2` is the elisp package.
    inherit (pkgs) aria2;
    npmDepsHash = npmHashes.eaf-browser;
  };

  eaf-pdf-viewer = call ./pdf-viewer.nix inputs.eaf-pdf-viewer { };

  eaf-file-manager = call ./file-manager.nix inputs.eaf-file-manager {
    npmDepsHash = npmHashes.eaf-file-manager;
  };

  eaf-image-viewer = call ./image-viewer.nix inputs.eaf-image-viewer {
    npmDepsHash = npmHashes.eaf-image-viewer;
  };
in
{
  inherit
    eaf-browser
    eaf-pdf-viewer
    eaf-file-manager
    eaf-image-viewer
    ;

  # Same signature as nixpkgs' `emacsPackages.eaf.withApplications`, so the call
  # site stays a one-liner. Takes the app derivations directly: the framework
  # reads `passthru.eafPythonDeps` off each one to assemble its interpreter.
  withApplications = enabledApps: call ./framework.nix inputs.eaf { inherit enabledApps; };
}
