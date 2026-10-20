# Vendored from nixpkgs:
#   .../elisp-packages/manual-packages/eaf-pdf-viewer/package.nix
#
# Changes from upstream: `src`/`version` come from the flake input and
# `updateScript` is dropped. No npm deps — this app ships no package.json.
{
  lib,
  melpaBuild,
  # Source, from the flake input
  src,
  version,
}:
melpaBuild {
  pname = "eaf-pdf-viewer";
  inherit src version;

  files = ''("*.el" "*.py")'';

  passthru.eafPythonDeps =
    ps: with ps; [
      packaging
      pymupdf
    ];

  meta = {
    description = "Fastest PDF Viewer in Emacs";
    homepage = "https://github.com/emacs-eaf/eaf-pdf-viewer";
    license = lib.licenses.gpl3Only;
  };
}
