;;; ui/doom.el --- doom ui/doom port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/doom.
;;; Code:

;;; :ui doom (themes bits)
;; pos-tip is not a declared dep; the setq is harmless if it's never loaded.
(setq pos-tip-internal-border-width 6
      pos-tip-border-width 1)

(leaf doom-themes
  :ensure t
  ;; doom's solaire-mode (dim non-focussed buffers) is not in this config's
  ;; package set; dropped. Theme loading itself lives in theme-config.el.
  :hook (doom-load-theme . doom-themes-org-config)
  :init
  (setq doom-theme 'doom-one))

;;; ui/doom.el ends here
