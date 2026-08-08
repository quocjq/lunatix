;;; completion/corfu.el --- doom completion/corfu port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/completion/corfu.
;;; Code:

(leaf corfu
  :ensure t
  :demand t
  :config
  (setq corfu-auto t
        global-corfu-modes '((not erc-mode circe-mode help-mode gud-mode vterm-mode) t)
        corfu-cycle t
        corfu-preselect 'prompt
        corfu-count 16
        corfu-max-width 120
        corfu-on-exact-match nil
        corfu-quit-at-boundary 'separator
        corfu-quit-no-match corfu-quit-at-boundary)
  (add-to-list 'corfu-continue-commands #'+corfu/move-to-minibuffer)
  (add-to-list 'corfu-continue-commands #'+corfu/smart-sep-toggle-escape)
  (add-hook 'evil-insert-state-exit-hook #'corfu-quit)
  (global-corfu-mode 1)
  (corfu-popupinfo-mode 1))

(leaf corfu-auto
  :ensure nil
  :after corfu
  :config
  (setq corfu-auto-delay 0.24
        corfu-auto-prefix 2)
  (add-to-list '+corfu-inhibit-auto-functions #'evil-replace-state-p))

(leaf cape
  :ensure t
  :defer t
  :config
  (add-hook 'prog-mode-hook
            (lambda ()
              (add-hook 'completion-at-point-functions #'cape-file -10 t)))
  (add-hook 'org-mode-hook
            (lambda ()
              (add-hook 'completion-at-point-functions #'cape-elisp-block 0 t)))
  (add-hook 'markdown-mode-hook
            (lambda ()
              (add-hook 'completion-at-point-functions #'cape-elisp-block 0 t)))
  (setq cape-dabbrev-check-other-buffers t)
  (add-hook 'prog-mode-hook
            (lambda ()
              (add-hook 'completion-at-point-functions #'cape-dabbrev 20 t)))
  (add-hook 'text-mode-hook
            (lambda ()
              (add-hook 'completion-at-point-functions #'cape-dabbrev 20 t)))
  (add-hook 'eshell-mode-hook
            (lambda ()
              (add-hook 'completion-at-point-functions #'cape-dabbrev 20 t)))
  (advice-add #'lsp-completion-at-point :around #'cape-wrap-noninterruptible)
  (advice-add #'lsp-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add #'comint-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add #'pcomplete-completions-at-point :around #'cape-wrap-nonexclusive))

(leaf corfu-history
  :ensure nil
  :after corfu
  :config
  (corfu-history-mode 1))

(leaf nerd-icons-corfu
  :ensure t
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(leaf nerd-icons
  :ensure t
  :demand t
  :custom
  (nerd-icons-font-family "Symbols Nerd Font Mono"))

;; vertico-map binds (doom completion/vertico)
(general-define-key
  :keymaps 'vertico-map
  "M-RET" #'vertico-exit-input
  "C-j"   #'vertico-next
  "C-k"   #'vertico-previous
  "C-h"   (lambda () (interactive)
            (when (eq 'file (vertico--metadata-get 'category))
              (vertico-directory-up)))
  "C-l"   #'+vertico/enter-or-preview
  "DEL"   #'vertico-directory-delete-char)

;;; completion/corfu.el ends here
