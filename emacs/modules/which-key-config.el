;;; which-key-config.el --- discoverable keys  -*- lexical-binding: t; -*-

(leaf which-key
  :ensure t
  :demand t
  :config
  (which-key-mode 1)
  (setq which-key-idle-delay 0.3))
;;; which-key-config.el ends here

(provide 'which-key-config)
