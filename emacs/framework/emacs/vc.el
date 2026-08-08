;;; emacs/vc.el --- doom emacs/vc port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/emacs/vc.
;;; Code:

;;; VC (doom emacs/vc)
(leaf vc
  :ensure nil
  :defer t
  :config
  (setq vc-follow-symlinks t))

;;; emacs/vc.el ends here
