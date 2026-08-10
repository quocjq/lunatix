;;; projectile.el --- project management (doom uses projectile)  -*- lexical-binding: t; -*-

(leaf projectile
  :ensure t
  :demand t
  
  :config
  (projectile-mode 1)
  (setq projectile-switch-project-action #'projectile-find-file
        projectile-find-dir-includes-top-level t
        ;; search inside files with ripgrep (fast), esp. git repos
        projectile-search-backend 'ripgrep
        projectile-use-git-grep t))

(leaf consult-projectile
  :ensure t
  :after projectile
  )
;;; projectile.el ends here
(provide 'projectile-config)
