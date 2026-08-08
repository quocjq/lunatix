# Vendored from nixpkgs:
#   .../elisp-packages/manual-packages/eaf-file-manager/package.nix
#
# Changes from upstream: `src`/`version` come from the flake input, the
# `fetchNpmDeps` hash comes from ./npm-hashes.nix, and `updateScript` is dropped.
{
  lib,
  melpaBuild,
  # Dependencies
  fd,
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
  pname = "eaf-file-manager";
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

  postPatch = ''
    substituteInPlace buffer.py \
      --replace-fail "shutil.which(\"fd\")" "shutil.which(\"${lib.getExe fd}\")" \
      --replace-fail "return \"fd\"" "return \"${lib.getExe fd}\""
  '';

  postBuild = ''
    npm run build
  '';

  files = ''("*.el" "*.py" "*.js" "src")'';

  postInstall = ''
    LISPDIR=$out/share/emacs/site-lisp/elpa/${finalAttrs.ename}-${finalAttrs.melpaVersion}
    touch node_modules/.nosearch
    cp -r node_modules $LISPDIR/
    cp -r dist $LISPDIR/
  '';

  passthru.eafPythonDeps =
    ps: with ps; [
      pypinyin
      pygments
      exif
    ];

  meta = {
    description = "File manager application for the EAF";
    homepage = "https://github.com/emacs-eaf/eaf-file-manager";
    license = lib.licenses.gpl3Only;
  };
})
