;;; checkers-config.el --- doom :checkers (syntax)  -*- lexical-binding: t; -*-

(leaf flycheck
  :ensure t
  :demand t
  :hook (prog-mode . flycheck-mode)
  :config
  (setq flycheck-indication-mode 'right-fringe))

(leaf flycheck-popup-tip
  :ensure t
  :after flycheck
  :hook (flycheck-mode . flycheck-popup-tip-mode))

;;; checkers-config.el ends here
(provide 'checkers-config)
