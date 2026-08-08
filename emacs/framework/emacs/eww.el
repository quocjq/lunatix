;;; emacs/eww.el --- doom emacs/eww port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/emacs/eww.
;;; Code:

;;; Eww (doom emacs/eww)
(leaf eww
  :ensure nil
  :commands eww
  :config
  (setq eww-search-prefix "https://duckduckgo.com/html/?q="))

;;; emacs/eww.el ends here
