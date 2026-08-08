;;; completion/vertico.el --- doom completion/vertico port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/completion/vertico.
;;; Code:

(leaf vertico
  :ensure t
  :demand t
  :config
  (setq vertico-resize nil
        vertico-count 17
        vertico-cycle t)
  (setq-default completion-in-region-function
                (lambda (&rest args)
                  (apply (if vertico-mode
                             #'consult-completion-in-region
                           #'completion--in-region)
                         args)))
  (advice-add #'completing-read-multiple :filter-args #'+vertico-crm-indicator)
  (add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy)
  (add-hook 'minibuffer-setup-hook #'vertico-repeat-save)
  (vertico-mode 1))

(leaf orderless
  :ensure t
  :demand t
  :config
  (setq orderless-affix-dispatch-alist
        '((?! . orderless-without-literal)
          (?& . orderless-annotation)
          (?% . char-fold-to-regexp)
          (?` . orderless-initialism)
          (?= . orderless-literal)
          (?^ . orderless-literal-prefix)
          (?~ . orderless-flex))
        orderless-style-dispatchers
        '(+vertico-orderless-dispatch +vertico-orderless-disambiguation-dispatch))
  (add-to-list
   'completion-styles-alist
   '(+vertico-basic-remote-try-completion
     +vertico-basic-remote-all-completions
     "Use basic completion on remote files only"))
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles orderless partial-completion)))
        orderless-component-separator #'orderless-escapable-split-on-space)
  (set-face-attribute 'completions-first-difference nil :inherit nil))

(leaf consult
  :ensure t
  :demand t
  :config
  (setq consult-project-function #'luna-project-root
        consult-narrow-key "<"
        consult-line-numbers-widen t
        consult-async-min-input 2
        consult-async-refresh-delay 0.15
        consult-async-input-throttle 0.2
        consult-async-input-debounce 0.1)
  (consult-customize
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file
   :preview-key "C-SPC")
  (consult-customize consult-theme :preview-key '("C-SPC" :debounce 0.5 any))
  (advice-add #'consult-recent-file :before (lambda (&rest _) (recentf-mode +1)))
  (advice-add #'consult-buffer :before (lambda (&rest _) (recentf-mode +1))))

(leaf marginalia
  :ensure t
  :demand t
  :config
  ;; nerd-icons-completion dropped: its `nerd-icons-completion-get-icon'
  ;; cl-generic has no method for the `command' category, which breaks M-x
  ;; (cl-no-applicable-method). Completion icons are cosmetic — not worth a
  ;; broken minibuffer.
  (marginalia-mode 1))

;;; completion/vertico.el ends here
