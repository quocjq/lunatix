#!/usr/bin/env bash
# Smoke test: load init.el with errors fatal, then assert the doom look/feel
# invariants actually work. Exit non-zero on any failure.
#
# Usage:
#   EMACS="$(nix build .#emacs --print-out-paths)/bin/emacs" ./test.sh
set -euo pipefail

EMACS="${EMACS:-emacs}"

"$EMACS" --batch \
  --eval '(setq debug-on-error t)' \
  --eval '(setq package-enable-at-startup nil)' \
  --eval '(setq user-emacs-directory (make-temp-file "emacs-smoke-" t))' \
  -l "$(dirname "$0")/init.el" \
  --eval '(progn
            (lunaris-stage-2)
            (unless (evil-mode 1) (error "evil-mode not active"))
            (unless (key-binding (kbd "SPC f f")) (error "SPC leader unbound"))
            (unless (lookup-key evil-normal-state-map (kbd "SPC b b")) (error "SPC b b missing"))
            (unless (lookup-key evil-normal-state-map (kbd "SPC g g")) (error "SPC g g missing"))
            (unless (lookup-key evil-normal-state-map (kbd "SPC p f")) (error "SPC p f missing"))
            (unless (lookup-key evil-normal-state-map (kbd "SPC s s")) (error "SPC s s missing"))
            (unless (lookup-key evil-normal-state-map (kbd "SPC :")) (error "SPC M-x missing"))
            (unless (lookup-key evil-normal-state-map (kbd "SPC w")) (error "SPC w missing"))
            (unless (custom-theme-p (quote doom-monokai-octagon)) (error "doom-monokai-octagon not loaded"))
            (unless (bound-and-true-p doom-modeline-mode) (error "doom-modeline off"))
            (unless (bound-and-true-p which-key-mode) (error "which-key off"))
            (unless (fboundp (quote evil-collection-init)) (error "evil-collection missing"))
            (unless (fboundp (quote +dashboard-init-h)) (error "dashboard missing"))
            (unless (bound-and-true-p vertico-mode) (error "vertico off"))
            (unless (fboundp (quote consult-line)) (error "consult missing"))
            (unless (fboundp (quote corfu-mode)) (error "corfu missing"))
            (unless (fboundp (quote marginalia-mode)) (error "marginalia missing"))
            (unless (fboundp (quote magit-status)) (error "magit missing"))
            (unless (locate-library "lsp-mode") (error "lsp missing"))
            (unless (bound-and-true-p smartparens-mode) (error "smartparens off"))
            (unless (bound-and-true-p editorconfig-mode) (error "editorconfig off"))
            (unless (fboundp (quote vterm)) (error "vterm missing"))
            (unless (locate-library "wl") (error "wanderlust not built"))
            (unless (locate-library "elfeed") (error "elfeed not built"))
            (unless (locate-library "circe") (error "circe not built"))
            (unless (bound-and-true-p evil-goggles-mode) (error "evil-goggles off"))
            (unless (fboundp (quote persp-mode)) (error "persp-mode missing"))
            (unless (bound-and-true-p ultra-scroll-mode) (error "ultra-scroll off"))
            (unless (fboundp (quote embark-act)) (error "embark missing"))
            (when menu-bar-mode (error "menu-bar still on"))
            (when tool-bar-mode (error "tool-bar still on"))
            (when scroll-bar-mode (error "scroll-bar still on"))
            (message "assertions: ok"))' \
  -f kill-emacs
