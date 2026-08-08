;;; term/vterm.el --- doom term/vterm port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/term/vterm.
;;; Code:

(leaf vterm
  :ensure t
  :commands vterm
  :config
  (setq vterm-max-scrollback 10000))

;;; term/vterm.el ends here
