# Vendored from nixpkgs:
#   .../elisp-packages/manual-packages/eaf-browser/default.nix
#
# Changes from upstream: `src`/`version` come from the flake input, the
# `fetchNpmDeps` hash comes from ./npm-hashes.nix, and `updateScript` is dropped.
{
  lib,
  melpaBuild,
  # Dependencies
  #
  # NOTE: `aria2` must be passed in explicitly by the caller. Inside the emacs
  # package set the name resolves to the *elisp* aria2 package, not the binary;
  # nixpkgs re-injects it the same way in manual-packages.nix.
  aria2,
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
  pname = "eaf-browser";
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
      --replace-fail "aria2_args = [\"aria2c\"]" "aria2_args = [\"${lib.getExe aria2}\"]"
  '';

  files = ''("*.el" "*.py" "easylist.txt" "aria2-ng")'';

  postInstall = ''
    LISPDIR=$out/share/emacs/site-lisp/elpa/${finalAttrs.ename}-${finalAttrs.melpaVersion}
    touch node_modules/.nosearch
    cp -r node_modules $LISPDIR/
  '';

  # `pycookiecheat` is not in upstream's dependencies.json but `buffer.py`
  # imports it lazily when pulling cookies from Chrome, so keep it.
  passthru.eafPythonDeps =
    ps: with ps; [
      pysocks
      pycookiecheat
    ];

  meta = {
    description = "Modern browser in Emacs";
    homepage = "https://github.com/emacs-eaf/eaf-browser";
    license = lib.licenses.gpl3Only;
  };
})
