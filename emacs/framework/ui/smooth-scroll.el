;;; ui/smooth-scroll.el --- doom ui/smooth-scroll port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/smooth-scroll.
;;; Code:

;;; :ui smooth-scroll
(leaf ultra-scroll
  :ensure t
  :defer t
  :config
  (ultra-scroll-mode 1)
  (add-hook 'ultra-scroll-hide-functions #'hl-todo-mode)
  (add-hook 'ultra-scroll-hide-functions #'diff-hl-flydiff-mode)
  (add-hook 'ultra-scroll-hide-functions #'jit-lock-mode))
;; good-scroll (+interpolate flag) isn't in this config's package set; the
;; `+interpolate' flag is off -- dropped.

;;; ui/smooth-scroll.el ends here
