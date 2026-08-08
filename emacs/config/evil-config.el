;;; evil-config.el --- vim emulation, doom-style  -*- lexical-binding: t; -*-

(leaf evil
  :ensure t
  :demand t
  ;; evil-want-* vars are set in init.el (before anything can load evil)
  :config
  (evil-mode 1)
  (delete-selection-mode 1)
  ;; doom-style cursor: type per state, color via a state-entry function.
  ;; emacs state = flashy warning color (pink), normal = theme cursor (white).
  (setq evil-default-cursor '+evil-default-cursor-fn
        evil-normal-state-cursor 'box
        evil-emacs-state-cursor  '(box +evil-emacs-cursor-fn)
        evil-insert-state-cursor 'bar
        evil-visual-state-cursor 'hollow)
  (defun +evil-default-cursor-fn ()
    (evil-set-cursor-color (get 'cursor 'evil-normal-color)))
  (defun +evil-emacs-cursor-fn ()
    (evil-set-cursor-color (get 'cursor 'evil-emacs-color)))
  (defun +evil-update-cursor-color-h (&rest _)
    (put 'cursor 'evil-emacs-color  (face-foreground 'warning))
    (put 'cursor 'evil-normal-color (face-background 'cursor)))
  (add-hook 'luna-load-theme-hook #'+evil-update-cursor-color-h)
  (advice-add 'load-theme :after #'+evil-update-cursor-color-h))

(leaf evil-collection
  :ensure t
  :defer t
  :config
  (evil-collection-init))

(leaf evil-commentary
  :ensure t
  :demand t
  :config
  (evil-commentary-mode 1))
;;; evil-config.el ends here

(provide 'evil-config)
