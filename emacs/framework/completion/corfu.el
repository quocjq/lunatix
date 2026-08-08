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

;; Emacs 30.2 puts a bare `t' in lisp-mode capf lists meaning "also run the
;; default (tags) completion". corfu's completion-in-region chokes on it
;; (`listp, t') and elisp completion stops working. Drop the marker — tags
;; completion is vestigial.
(dolist (hook '(emacs-lisp-mode-hook lisp-mode-hook lisp-interaction-mode-hook
                scheme-mode-hook))
  (add-hook hook
            (lambda ()
              (setq-local completion-at-point-functions
                          (delq t (buffer-local-value
                                   'completion-at-point-functions
                                   (current-buffer)))))))

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

;;; completion/corfu.el ends here
