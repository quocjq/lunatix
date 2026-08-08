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
            (lunaris-stage-2-now)
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
            (unless (locate-library "vertico") (error "vertico missing"))
            (unless (locate-library "consult") (error "consult missing"))
            (unless (locate-library "corfu") (error "corfu missing"))
            (unless (locate-library "marginalia") (error "marginalia missing"))
            (unless (locate-library "magit") (error "magit missing"))
            (unless (locate-library "lsp-mode") (error "lsp missing"))
            (unless (bound-and-true-p lnav-mode) (error "lnav mode off"))
            (unless (fboundp (quote lnav-jump-forward)) (error "lnav missing"))
            (unless (fboundp (quote lnav-show-pair-mode)) (error "lnav extras missing"))
            (unless (fboundp (quote lnav-typing-mode)) (error "lnav typing missing"))
            (unless (fboundp (quote lnav-evil-inside-chunk)) (error "lnav-evil missing"))
            (unless (eq (lookup-key evil-emacs-state-map (kbd "DEL")) (quote delete-backward-char))
              (error "emacs-state DEL not delete-backward-char"))
            (unless (eq (cadr evil-emacs-state-cursor) (quote +evil-emacs-cursor-fn))
              (error "emacs-state cursor fn missing"))
            (unless (eq evil-normal-state-cursor (quote box))
              (error "normal-state cursor not box"))
            (unless (locate-library "editorconfig") (error "editorconfig missing"))
            (unless (locate-library "vterm") (error "vterm missing"))
            (unless (locate-library "wl") (error "wanderlust not built"))
            (unless (locate-library "elfeed") (error "elfeed not built"))
            (unless (locate-library "circe") (error "circe not built"))
            (unless (locate-library "evil-goggles") (error "evil-goggles missing"))
            (unless (locate-library "persp-mode") (error "persp-mode missing"))
            (unless (locate-library "ultra-scroll") (error "ultra-scroll missing"))
            (unless (locate-library "embark") (error "embark missing"))
            (when menu-bar-mode (error "menu-bar still on"))
            (when tool-bar-mode (error "tool-bar still on"))
            (when scroll-bar-mode (error "scroll-bar still on"))
            (lunaris-doctor)
            (unless (> (lunaris-doctor-count (quote ok)) 0) (error "doctor: no ok reports"))
            (message "assertions: ok"))' \
  -f kill-emacs
