;;; which-key-config.el --- discoverable keys  -*- lexical-binding: t; -*-

(leaf which-key
  :ensure t
  :demand t
  :config
  (which-key-mode 1)
  (setq which-key-idle-delay 0.4
        ;; groups first, then alphabetical; hide the full prefix chain
        which-key-sort-order nil
        which-key-max-description-length 40
        which-key-show-prefix 'left
        which-key-allow-imprecise-window-fit t
        which-key-show-early-on-C-h t
        which-key-use-C-h-commands t
        which-key-add-column-padding 2))
;;; which-key-config.el ends here
(provide 'which-key-config)
