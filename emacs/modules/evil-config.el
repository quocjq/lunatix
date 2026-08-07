;;; evil-config.el --- vim emulation, doom-style  -*- lexical-binding: t; -*-

(leaf evil
  :ensure t
  :demand t
  :init
  (setq evil-want-C-i-jump nil
        evil-want-C-u-scroll t
        evil-want-Y-yank-to-eol t
        evil-want-keybinding nil)
  :config
  (evil-mode 1)
  (delete-selection-mode 1))

(leaf evil-collection
  :ensure t
  :demand t
  :config
  (evil-collection-init))
;;; evil-config.el ends here

(provide 'evil-config)
