# lnav emacs package, built from the `lnav` flake input (github, flake =
# false — not in melpa/elpa/emacs-overlay). Mimics the _eaf/scope.nix
# pattern: built inside the emacs package scope and added via
# `extraEmacsPackages`, which is emacs-overlay's sanctioned way to add
# non-melpa packages. Version is read from lnav.el's header.
{ inputs, pkgs, epkgs }:
let
  pname = "lnav";
  src = inputs.lnav;
  version = builtins.head (
    builtins.match ".*Version: ([0-9.]+).*"
      (builtins.readFile "${src}/lnav.el"));
in {
  lnav = epkgs.trivialBuild {
    inherit pname src version;
    packageRequires = [ ];
    postPatch = ''
      cat > lnav-pkg.el <<'PKGEOF'
      (define-package "lnav" "${version}" "Mode-agnostic bracket navigation and editing"
        '((emacs "29.1")))
      PKGEOF
    '';
    # trivialBuild installs only `${pname}.el*`; lnav ships several files
    # (flash/structural/typing/extras + evil), pulled in by `require` at the
    # end of lnav.el — copy them into the same dir lnav.el landed in. The
    # byte-compiled lnav-evil.elc is broken (evil-define-text-object compiles
    # a void varref); drop it so lnav-evil loads from source.
    postInstall = ''
      dest="$(dirname "$(find "$out" -name lnav.el | head -1)")"
      for f in lnav-flash lnav-structural lnav-typing lnav-extras lnav-evil; do
        install -m644 "$src/$f.el" "$dest/$f.el"
      done
      rm -f "$dest/lnav-evil.elc"
    '';
  };
}
