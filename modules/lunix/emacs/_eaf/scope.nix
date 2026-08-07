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

  withApplications = enabledApps: call ./framework.nix inputs.eaf { inherit enabledApps; };
}
