;;; ui/ui.el --- doom :ui group file  -*- lexical-binding: t; -*-
;;; Module files in this dir are gated by `(modulep! :ui <module>)';
;;; this group file always loads first.

;;; ui-config.el --- visual chrome, doom :ui set  -*- lexical-binding: t; -*-

;; Port of doom-emacs :ui submodules: deft, doom, dashboard, hl-todo,
;; indent-guides, ligatures, modeline, ophints, popup, smooth-scroll,
;; vc-gutter, window-select, workspaces.
;;
;; ui/unicode has no config.el -- skipped (its autoload only hooks doom-core's
;; `after-setting-font-hook'); the unicode-fonts package is still declared below.
;;
;; APROX markers note where doom-core machinery was replaced with a vanilla or
;; popper equivalent (doom-popup, doom/help, nerd-icons, doom's no-op hooks).

;;; ui/ui.el ends here
