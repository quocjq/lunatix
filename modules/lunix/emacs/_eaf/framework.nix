# Vendored from nixpkgs:
#   pkgs/applications/editors/emacs/elisp-packages/manual-packages/
#     emacs-application-framework/package.nix
#
# Changes from upstream:
#   * `src` and `version` are arguments (fed from the `eaf` flake input by
#     ./scope.nix) instead of an inline `fetchFromGitHub` + literal version;
#   * `updateScript` dropped — `unstableGitUpdater` cannot bump a flake input.
# Everything else, in particular the `enabledApps` composition and the `eaf.el`
# patching, is carried over verbatim.
{
  stdenv,
  lib,
  melpaBuild,
  symlinkJoin,
  # Python dependency
  python3,
  # Emacs dependencies
  all-the-icons,
  # Other dependencies
  wmctrl,
  xdotool,
  # Source, from the flake input
  src,
  version,
  # Sub-applications in the framework
  enabledApps ? [ ],
}:
let
  # Each app exports its Python requirements as `passthru.eafPythonDeps`; they
  # are merged into one interpreter here. This is why `enabledApps` must be the
  # app derivations themselves and not, say, a symlinkJoin of them — a joined
  # derivation carries no `eafPythonDeps` and every app's deps would silently
  # disappear from the env.
  appPythonDeps = map (item: item.eafPythonDeps) enabledApps;
  pythonPackageLists = [
    (
      ps: with ps; [
        epc
        lxml
        pyqt6
        pyqt6-sip
        pyqt6-webengine
        sexpdata
        tld
      ]
    )
  ]
  ++ appPythonDeps;
  pythonPkgs = ps: builtins.concatLists (map (f: f ps) pythonPackageLists);
  pythonEnv = python3.withPackages pythonPkgs;

  wmctrlExe = lib.getExe wmctrl;
  xdotoolExe = lib.optionalString (lib.meta.availableOn stdenv.hostPlatform xdotool) (
    lib.getExe xdotool
  );

  appsDrv = symlinkJoin {
    name = "emacs-application-framework-apps";
    paths = enabledApps;
  };
in
melpaBuild (finalAttrs: {
  pname = "eaf";
  inherit src version;

  packageRequires = [ all-the-icons ];

  # `--replace-fail` aborts the build if a target string is gone, which is the
  # intended signal that upstream refactored `eaf.el` — re-read the file and fix
  # the patterns rather than loosening the flag.
  postPatch = ''
    substituteInPlace eaf.el \
      --replace-fail "\"python.exe\" \"python3\"" "\"python.exe\" \"${pythonEnv.interpreter}\""
    substituteInPlace eaf.el \
      --replace-fail "(executable-find \"wmctrl\")" "(executable-find \"${wmctrlExe}\")" \
      --replace-fail "(shell-command-to-string \"wmctrl -m\")" "(shell-command-to-string \"${wmctrlExe} -m\")" \
      --replace-fail "\"wmctrl -i -a \$(wmctrl -lp | awk -vpid=\$PID '\$3==%s {print \$1; exit}')\"" "\"${wmctrlExe} -i -a \$(${wmctrlExe} -lp | awk -vpid=\$PID '\$3==%s {print \$1; exit}')\""
    substituteInPlace eaf.el \
      --replace-fail "(executable-find \"xdotool\")" "(executable-find \"${xdotoolExe}\")" \
      --replace-fail "(shell-command-to-string \"xdotool getactivewindow getwindowname\")" "(shell-command-to-string \"${xdotoolExe} getactivewindow getwindowname\")"
  '';

  files = ''("*.el" "*.py" "applications.json" "core" "extension")'';

  preInstall = ''
    EMACSLOADPATH="$EMACSLOADPATH:core/"
  '';

  postInstall = ''
    LISPDIR=$out/share/emacs/site-lisp/elpa/${finalAttrs.ename}-${finalAttrs.melpaVersion}
    APPLISPDIR=${appsDrv}/share/emacs/site-lisp/elpa
    if [ -d $APPLISPDIR ]; then
      cp -r $APPLISPDIR/. $LISPDIR/app/
    fi
    NATDIR=$out/share/emacs/native-lisp
    APPNATDIR=${appsDrv}/share/emacs/native-lisp
    if [ -d $APPNATDIR ]; then
      cp -r $APPNATDIR/. $NATDIR/
    fi
  '';

  meta = {
    description = "Extensible framework of Emacs";
    homepage = "https://github.com/emacs-eaf/emacs-application-framework";
    license = lib.licenses.gpl3Only;
  };
})
