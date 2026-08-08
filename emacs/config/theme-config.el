;;; theme-config.el --- doom look  -*- lexical-binding: t; -*-

(leaf doom-themes
  :ensure t
  :demand t
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (doom-themes-org-config)
  (setq doom-theme 'doom-monokai-octagon)
  (load-theme doom-theme t))

(leaf doom-modeline
  :ensure t
  :demand t
  :config
  (setq doom-modeline-buffer-file-name-style 'truncate-all
        doom-modeline-minor-modes t)
  (doom-modeline-mode 1))

;; doom font
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 18 :weight 'medium))
;;; theme-config.el ends here
(provide 'theme-config)
