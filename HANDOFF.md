# HANDOFF — keybind consolidation + vundo (checkpoint, gen 3)

State as of the canary trip. Everything below is verified-by-execution unless marked
[IN PROGRESS] or [UNVERIFIED].

## Task (user request, in order)
1. "setting undosystem in evil mode and add vundo, add keybind for undo tree" — undo-fu
   stays as evil engine; vundo added for the visual tree; `SPC u` = vundo.
2. "Add a rule somewhere in config, all keybind must be in the keybind.el file in /config"
   — single canonical keybinding file + enforcing rule.

## DONE (working tree, not committed)
- `git mv emacs/config/keybindings-config.el emacs/config/keybind.el`; RULE header added.
- ALL bindings moved from ~28 framework/config files into `config/keybind.el`, grouped by
  package under `(after! <pkg> ...)`. Moved: org (+org-agenda/evil-org/evil-org-agenda),
  emacs-lisp, helpful, buttercup, magit/forge, pass, pdf, lsp, css, json, php, dashboard
  (mode-hook, no feature to after!), persp-mode, winum, diff-hl, circe/lui/irc, elfeed,
  calfw, python/pytest/pipenv, rustic, common-lisp/sly, ruby/rake/rspec/minitest, agda,
  latex/LaTeX/preview/reftex/cdlatex/bibtex, go-mode/go-ts-mode, nix-mode/nix-ts-mode,
  markdown/evil-markdown, tabulated-list, lnav (C-c clear), vundo.
- Left in place (documented exceptions in keybind.el header): per-buffer `current-local-map`
  binds (latex reftex-toc), calendar's `define-key keymap` inside a keymap-builder fn.
- vundo: `(leaf vundo :ensure t :commands vundo)` in framework/editor/file-templates.el
  undo section; leader `"u"` changed universal-argument → vundo.
- ALL framework/config .el files byte-compile clean with lunaris+leaf loaded (95/96; only
  personal.el fails standalone because it needs init.el's `lunatix-emacs-dir` — pre-existing).
- forward-sexp parse check passes on every file individually.

## ACTIVE BLOCKER — nix use-package scanner regression
- `nix build .#emacs` builds but detects only ~37-40 packages (old build: 372).
- New deps store `/nix/store/s3mrndga8...emacs-packages-deps` has only 50 elpa dirs; missing
  general, evil-commentary, org-modern, projectile, vertico, consult, corfu, magit, lsp-mode,
  denote, dirvish, auctex, circe, calfw, ... so config load fails ("Cannot load X").
- Scanner = emacs-overlay `parse.nix` `parsePackagesFromUsePackage`, pure-Nix `fromElisp`
  parser + recurse over `(leaf|use-package NAME :ensure ...)` forms. alwaysEnsure=true.
- Measured: init.el alone → 0 (expected, no leaf). init+config/*.el → 40. Adding framework
  dirs → still 40. So framework/*.el contributes ZERO leaf forms now → fromElisp swallows the
  framework subtree (a construct in an early framework file breaks form nesting).
- NOTE: same files via git HEAD concatenated → 372 (verified old count). So this is a
  regression from THIS session's edits, not a pre-existing overlay quirk.
- NOT yet located: the exact construct/file that breaks fromElisp. Bisect was interrupted
  (bisect2.nix has a syntax bug; also nix eval is slow ~1min each, prefer one eval scanning
  many checkpoints).

## Suspects (unverified)
- My edited files that touch big structural forms: org.el (removed 220 lines), keybind.el
  (new 1485-line file), sh.el, python.el, latex.el (leaf close parens), ruby/agda (leaf
  closes). fromElisp throw would FAIL the build; it doesn't, so the failure is a NESTING
  swallow, not a token error.

## Other confirmed working (earlier this session, committed+pushed)
- 84f14ea lnav replaces smartparens; b309291 cursor/backspace/lsp-dir; 4938c7a elisp font-lock
  (advice--cd*r); lnav flash label fix (pushed to ~/Proj/lnav, flake.lock updated).

## Environment / commands
- Emacs GUI probes hang the laptop — --batch only. Kill stray emacs PIDs (native-comp).
- Test: `E=$(nix path-info .#emacs|grep emacs-gtk3); D=/nix/store/s3mrndga8.../share/emacs/site-lisp;
  EMACS="$E/bin/emacs" EMACSLOADPATH="$D:" timeout 200 bash emacs/test.sh` (test.sh asserts lnav/
  cursor/DEL/evil). Deletes ~/.cache/lunatix-emacs first.
- Compile-check: load lunaris+leaf, byte-compile-file each file.
- Config repo symlinked to ~/.emacs.d (out-of-store); nix rebuild ONLY for package changes.
- Test.sh uses single-quoted --eval → use (quote sym) not 'sym.

## Next step
1. Fix bisect2.nix (drop `take`, use explicit subdir groups) → one nix eval scanning
   init+config+framework-dir-by-dir to find the FIRST dir/file whose addition drops the count.
2. With root cause file identified, check its fromElisp-visible structure (likely a comment/
   string/reader-construct the pure-Nix parser nests differently). Remember: old config with
   same emacs-overlay rev parsed to 372, so the fix is in MY config text.
3. Rebuild nix → full test green → commit + push.
