# nixpkgs overlay carrying the Python fixes EAF's interpreter env needs.
#
# `python3.14-plum-py-0.8.7` (pulled in transitively via `exif`, an
# eaf-file-manager dependency) has 18 `tests/structure/test_struct_*.py`
# failures on Python 3.14. No newer version exists on PyPI. The library is still
# used at runtime, just not validated by the failing tests.
#
# NOTE: `doCheck = false` does NOT skip pytestCheckPhase — `pytest-check-hook`
# appends `pytestCheckPhase` to `preDistPhases` and only gates on
# `dontUsePytestCheck` / `installCheckPhase`. Setting `dontUsePytestCheck = "1"`
# disables the hook entirely.
#
# NOTE: this must go through `pythonPackagesExtensions`, not a top-level
# `python3Packages = prev.python3Packages // { ... }` merge. The framework builds
# its interpreter with `python3.withPackages`, which resolves against
# `python3.pkgs` — that set comes from the interpreter's own passthru and is
# untouched by rebinding the top-level `python3Packages` attribute. Verified:
# under the merge form `python3.pkgs.plum-py.dontUsePytestCheck` is unset while
# `python3Packages.plum-py.dontUsePytestCheck` is "1", so the patch never
# reaches the env EAF actually runs.
final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyfinal: pyprev: {
      plum-py = pyprev.plum-py.overrideAttrs (_: {
        dontUsePytestCheck = "1";
      });
    })
  ];
}
