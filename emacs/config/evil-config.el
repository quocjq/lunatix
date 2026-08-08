;;; evil-config.el --- vim emulation, doom-style  -*- lexical-binding: t; -*-

(leaf evil
  :ensure t
  :demand t
  ;; evil-want-* vars are set in init.el (before anything can load evil)
  :config
  (evil-mode 1)
  (delete-selection-mode 1))

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
