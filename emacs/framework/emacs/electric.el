;;; emacs/electric.el --- doom emacs/electric port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/emacs/electric.
;;; Code:

;;; Electric (doom emacs/electric)
(leaf electric
  :ensure nil
  :defer t
  :config
  (electric-pair-mode 1)
  (electric-indent-mode 1)
  (electric-layout-mode 1))

;;; emacs/electric.el ends here
