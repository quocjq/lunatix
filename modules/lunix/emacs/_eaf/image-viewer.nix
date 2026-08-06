# Vendored from nixpkgs:
#   .../elisp-packages/manual-packages/eaf-image-viewer/package.nix
#
# Changes from upstream: `src`/`version` come from the flake input, the
# `fetchNpmDeps` hash comes from ./npm-hashes.nix, and `updateScript` is dropped.
{
  lib,
  melpaBuild,
  # JavaScript dependency
  nodejs,
  fetchNpmDeps,
  npmHooks,
  # Source, from the flake input
  src,
  version,
  npmDepsHash,
}:
melpaBuild (finalAttrs: {
  pname = "eaf-image-viewer";
  inherit src version;

  env.npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-npm-deps";
    inherit (finalAttrs) src;
    hash = npmDepsHash;
  };

  nativeBuildInputs = [
    nodejs
    npmHooks.npmConfigHook
  ];

  files = ''("*.el" "*.py" "*.html")'';

  postInstall = ''
    LISPDIR=$out/share/emacs/site-lisp/elpa/${finalAttrs.ename}-${finalAttrs.melpaVersion}
    touch node_modules/.nosearch
    cp -r node_modules $LISPDIR/
  '';

  passthru.eafPythonDeps = ps: [ ];

  meta = {
    description = "Image viewer application for the EAF";
    homepage = "https://github.com/emacs-eaf/eaf-image-viewer";
    license = lib.licenses.gpl3Only;
  };
})
