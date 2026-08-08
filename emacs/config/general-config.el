;;; general-config.el --- keybinding layer + leader definer  -*- lexical-binding: t; -*-

(leaf general
  :ensure t
  :demand t
  :config
  (general-evil-setup t)

  (general-create-definer lunatix-leader
    :states '(normal visual)
    :prefix "SPC"
    :global-prefix "C-SPC")

  ;; The full leader tree lives in keybindings-config.el (loads after this).

  (recentf-mode 1)

  ;; doom: q in normal state closes the current window
  (general-define-key :states '(normal visual) "q" #'delete-window))
;;; general-config.el ends here
(provide 'general-config)
