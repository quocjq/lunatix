;;; completion-config.el --- vertico/consult/corfu stack, doom :completion  -*- lexical-binding: t; -*-

;; dlet shim (doom-compat gap): dynamic let with optional overrides
(defmacro dlet (bindings &rest body)
  (declare (indent 1))
  `(let ,(mapcar (lambda (b) (if (symbolp b) (list b nil) b)) bindings)
     ,@(mapcar (lambda (b) (unless (symbolp b) `(set ,(car b) ,(cadr b)))) bindings)
     ,@body))

;; doom completion/corfu vars
(defcustom +corfu-want-ret-to-confirm t
  "t: insert if selected, passthrough otherwise; nil: passthrough; both: both."
  :type '(choice (const t) (const nil) (const both) (const minibuffer)))
(defcustom +corfu-buffer-scanning-size-limit (* 1 1024 1024)
  "Size limit for buffers scanned by `cape-dabbrev'."
  :type 'integer)
(defcustom +corfu-want-minibuffer-completion t
  "Whether to enable Corfu in the minibuffer."
  :type '(choice (const nil) (const aggressive) (const t)))
(defcustom +corfu-inhibit-auto-functions ()
  "Predicates that inhibit `corfu-auto'."
  :type 'hook)

;; doom completion/corfu autoload helpers (copied)
(defun +corfu-dabbrev-friend-buffer-p (other-buffer)
  (< (buffer-size other-buffer) +corfu-buffer-scanning-size-limit))

(defun +corfu/move-to-minibuffer ()
  "Move list of candidates to your choice of minibuffer completion UI."
  (interactive)
  (unless completion-in-region--data
    (user-error "No completion active"))
  (pcase-let ((`(,beg ,end ,table ,pred ,extras) completion-in-region--data))
    (let ((completion-extra-properties extras)
          completion-cycle-threshold
          completion-cycling)
      (cond ((and (fboundp #'consult-completion-in-region))
             (consult-completion-in-region beg end table pred))
            ((user-error "No minibuffer completion UI available for moving to!"))))))

(defun +corfu/smart-sep-toggle-escape ()
  "Insert `corfu-separator' or toggle escape if it's already there."
  (interactive)
  (cond ((and (char-equal (char-before) corfu-separator)
              (char-equal (char-before (1- (point))) ?\\))
         (save-excursion (delete-char -2)))
        ((char-equal (char-before) corfu-separator)
         (save-excursion (backward-char 1) (insert-char ?\\)))
        ((call-interactively #'corfu-insert-separator))))

(defun +corfu/dabbrev-this-buffer ()
  "Like `cape-dabbrev', but only scans current buffer."
  (interactive)
  (require 'cape)
  (let ((cape-dabbrev-buffer-function #'current-buffer))
    (cape-dabbrev t)))

(defun +corfu/toggle-auto-complete (&optional interactive)
  "Toggle as-you-type completion in Corfu."
  (interactive (list 'interactive))
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when corfu-mode
        (if corfu-auto
            (remove-hook 'post-command-hook #'corfu-auto--post-command 'local)
          (add-hook 'post-command-hook #'corfu-auto--post-command nil 'local)))))
  (when interactive
    (message "Corfu auto-complete %s" (if corfu-auto "disabled" "enabled")))
  (setq corfu-auto (not corfu-auto)))

(defun +corfu/dabbrev-or-next (&optional arg)
  "Invoke `cape-dabbrev' but respect `evil-complete-all-buffers'."
  (interactive "p")
  (if corfu--candidates
      (corfu-next arg)
    (require 'cape)
    (let ((cape-dabbrev-buffer-function
           (if (bound-and-true-p evil-complete-all-buffers)
               #'cape-same-mode-buffers
             #'current-buffer)))
      (cape-dabbrev t)
      (when (> corfu--total 0)
        (corfu--goto (or arg 0))))))

(defun +corfu/dabbrev-or-last (&optional arg)
  "Invoke `cape-dabbrev' but respect `evil-complete-all-buffers'."
  (interactive "p")
  (if corfu--candidates
      (corfu-previous arg)
    (require 'cape)
    (let ((cape-dabbrev-buffer-function
           (if (bound-and-true-p evil-complete-all-buffers)
               #'cape-same-mode-buffers
             #'current-buffer)))
      (cape-dabbrev t)
      (when (> corfu--total 0)
        (corfu--goto (- corfu--total (or arg 1)))))))

;; doom completion/vertico autoload helpers (copied)
(defun +vertico-orderless-dispatch (pattern _index _total)
  "Like `orderless-affix-dispatch', but allows affixes to be escaped."
  (let ((len (length pattern))
        (alist orderless-affix-dispatch-alist))
    (when (> len 0)
      (cond
       ((and (= len 1) (alist-get (aref pattern 0) alist)) #'ignore)
       ((when-let* ((style (alist-get (aref pattern 0) alist))
                    ((not (char-equal (aref pattern (max (1- len) 1)) ?\\))))
          (cons style (substring pattern 1))))
       ((when-let* ((style (alist-get (aref pattern (1- len)) alist))
                    ((not (char-equal (aref pattern (max 0 (- len 2))) ?\\))))
          (cons style (substring pattern 0 -1))))))))

(defun +vertico-orderless-disambiguation-dispatch (pattern _index _total)
  "Disambiguation dispatch for orderless."
  (cond
   ((string-prefix-p "!" pattern) (cons 'orderless-without-literal (substring pattern 1)))
   ((string-prefix-p "=" pattern) (cons 'orderless-literal (substring pattern 1)))))

(defun +vertico-crm-indicator (args)
  "CRM indicator wrapper for `completing-read-multiple'."
  (cons (format "[CRM%s] %s"
                (replace-regexp-in-string "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" "" crm-separator)
                (car args))
        (cdr args)))

(defun +vertico/enter-or-preview ()
  "Enter directory or embark preview on current candidate."
  (interactive)
  (when (> 0 vertico--index)
    (user-error "No vertico session is currently active"))
  (if (and (let ((cand (vertico--candidate)))
             (or (string-suffix-p "/" cand)
                 (and (vertico--remote-p cand)
                      (string-suffix-p ":" cand))))
           (not (equal vertico--base ""))
           (eq 'file (vertico--metadata-get 'category)))
      (vertico-insert)
    (condition-case _ (+vertico/embark-preview)
      ('error (vertico-insert)))))

(defun +vertico/embark-preview ()
  "Previews candidate in vertico buffer, unless it's a consult command."
  (interactive)
  (unless (bound-and-true-p consult--preview-function)
    (unless (require 'embark nil t)
      (user-error "Embark not installed, aborting..."))
    (save-selected-window
      (dlet (embark-quit-after-action)
        (embark-dwim)))))

(defun +vertico/jump-list (jump)
  "Go to an entry in evil's (or better-jumper's) jumplist."
  (interactive
   (let (buffers)
     (require 'consult)
     (unwind-protect
         (list (consult--read
                (nreverse (delete-dups (delq nil (mapcar (lambda (pt) (marker-buffer pt))
                                                         evil--jumps))))
                :prompt "Jump to:"
                :sort nil :require-match t))
       (setq evil--jumps (cons (point-marker) evil--jumps)))))
  (when-let* ((marker (seq-find (lambda (pt) (equal (marker-buffer pt) (current-buffer)))
                                evil--jumps)))
    (goto-char marker)))

;;; Packages

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
  (setq consult-project-function #'doom-project-root
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
  (when (fboundp 'nerd-icons-completion-marginalia-setup)
    (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))
  (marginalia-mode 1))

(leaf nerd-icons-completion
  :ensure t
  :after marginalia
  :config
  (nerd-icons-completion-mode 1))

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

;; +childframe: vertico in a posframe (doom (vertico +icons +childframe))
(leaf vertico-posframe
  :ensure t
  :after vertico
  :demand t
  :config
  (vertico-posframe-mode 1)
  (setq vertico-posframe-parameters
        '((left-fringe . 8)
          (right-fringe . 8))))

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

;;; completion-config.el ends here
(provide 'completion-config)
