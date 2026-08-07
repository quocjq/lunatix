;;; emacs-config.el --- doom :emacs (builtin conveniences)  -*- lexical-binding: t; -*-

;;; Electric (doom emacs/electric)
(leaf electric
  :ensure nil
  :demand t
  :config
  (electric-pair-mode 1)
  (electric-indent-mode 1)
  (electric-layout-mode 1))

;;; Dired (doom emacs/dired)
(leaf dired
  :ensure nil
  :hook (dired-mode . dired-hide-details-mode)
  :config
  (setq dired-listing-switches "-alh"
        dired-recursive-copies 'always
        dired-recursive-deletes 'top))

(leaf nerd-icons-dired
  :ensure t
  :hook (dired-mode . nerd-icons-dired-mode))

;;; Ibuffer (doom emacs/ibuffer +icons)
(leaf ibuffer
  :ensure nil
  :commands ibuffer)

(leaf nerd-icons-ibuffer
  :ensure t
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

;;; Eww (doom emacs/eww)
(leaf eww
  :ensure nil
  :commands eww
  :config
  (setq eww-search-prefix "https://duckduckgo.com/html/?q="))

;;; Tramp (doom emacs/tramp)
(leaf tramp
  :ensure nil
  :commands tramp)

;;; VC (doom emacs/vc)
(leaf vc
  :ensure nil
  :defer t
  :config
  (setq vc-follow-symlinks t))

;;; emacs-config.el ends here
(provide 'emacs-config)
