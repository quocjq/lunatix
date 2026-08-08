;;; term/eshell.el --- doom term/eshell port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/term/eshell.
;;; Code:

(leaf eshell
  :ensure nil
  :commands eshell
  :config
  (setq eshell-history-size 10000
        eshell-buffer-maximum-lines 10000
        eshell-scroll-to-bottom-on-input 'all
        eshell-scroll-show-maximum-output t))

(leaf eshell-syntax-highlighting
  :ensure t
  :defer t
  :config
  (eshell-syntax-highlighting-global-mode 1))

(leaf eshell-up
  :ensure t
  :defer t
  :config
  (add-hook 'eshell-mode-hook (lambda () (require 'eshell-up))))

(leaf eshell-z
  :ensure t
  :defer t
  :config
  (add-hook 'eshell-mode-hook (lambda () (require 'eshell-z))))

(leaf esh-help
  :ensure t
  :defer t
  :config
  (setup-esh-help-eldoc))

(leaf eshell-did-you-mean
  :ensure t
  :defer t
  :config
  (eshell-did-you-mean-setup))

(leaf shrink-path
  :ensure t
  :defer t)

(leaf pcmpl-args
  :ensure t
  :defer t)

;;; term/eshell.el ends here
