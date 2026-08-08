;;; emacs/ibuffer.el --- doom emacs/ibuffer port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/emacs/ibuffer.
;;; Code:

;;; Ibuffer (doom emacs/ibuffer +icons)
(leaf ibuffer
  :ensure nil
  :commands ibuffer)

(leaf nerd-icons-ibuffer
  :ensure t
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

;;; emacs/ibuffer.el ends here
