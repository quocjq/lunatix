;;; editor-config.el --- doom :editor (format, whitespace, snippets, fold)  -*- lexical-binding: t; -*-

;;; Format (doom editor/format +onsave)
(defcustom +format-on-save-disabled-modes
  '(sql-mode tex-mode latex-mode LaTeX-mode org-msg-edit-mode)
  "Modes in which not to reformat on save.")

(leaf apheleia
  :ensure t
  :demand t
  :config
  (when (boundp 'apheleia-inhibit-functions)
    (add-hook 'apheleia-inhibit-functions
              (lambda ()
                (or (eq major-mode 'fundamental-mode)
                    (string-blank-p (buffer-name))
                    (eq +format-on-save-disabled-modes t)
                    (memq major-mode +format-on-save-disabled-modes)))))
  (add-hook 'prog-mode-hook #'apheleia-mode)
  (when (boundp 'apheleia-mode-map)
    (define-key apheleia-mode-map [remap basic-save-buffer] #'+format/save-buffer))
  (add-to-list 'apheleia-mode-alist '(sh-mode . shfmt)))

(defun +format/save-buffer ()
  "Format buffer then save."
  (interactive)
  (when apheleia-mode
    (apheleia-format-buffer))
  (save-buffer))

;;; Whitespace (doom editor/whitespace +guess +trim)
(defvar +whitespace-guess-excluded-modes
  '(pascal-mode so-long-mode emacs-lisp-mode coq-mode org-mode)
  "Modes where indentation shouldn't be auto-detected.")

(defvar +whitespace-guess-in-projects nil
  "If non-nil, guess indentation in project files too.")

(leaf whitespace
  :ensure nil
  :defer t
  :config
  (setq whitespace-line-column nil
        whitespace-style
        '(face indentation tabs tab-mark spaces space-mark newline newline-mark trailing)))

(leaf ws-butler
  :ensure t
  :hook (prog-mode . ws-butler-mode))

(leaf dtrt-indent
  :ensure t
  :hook ((change-major-mode-after-body read-only-mode) . +whitespace-guess-indentation-h)
  :config
  (setq dtrt-indent-run-after-smie t
        dtrt-indent-max-lines 2000))

(defun +whitespace-guess-indentation-h ()
  (unless (or (not after-init-time)
              (eq major-mode 'fundamental-mode)
              (member (substring (buffer-name) 0 1) '(" " "*"))
              (apply #'derived-mode-p +whitespace-guess-excluded-modes)
              buffer-read-only
              (and (not +whitespace-guess-in-projects)
                   (doom-project-root)))
    (dtrt-indent-mode +1)))

;;; Snippets (doom editor/snippets)
(leaf yasnippet
  :ensure t
  :demand t
  :hook (prog-mode . yas-minor-mode)
  :config
  (yas-reload-all))

(leaf yasnippet-snippets
  :ensure t
  :after yasnippet)

(leaf auto-yasnippet
  :ensure t
  :defer t)

;;; Fold (doom editor/fold)
(leaf vimish-fold
  :ensure t
  :demand t
  :config
  (vimish-fold-mode 1))

(leaf evil-vimish-fold
  :ensure t
  :after vimish-fold
  :config
  (evil-vimish-fold-mode 1))

;;; Parinfer (doom editor/parinfer)
(leaf parinfer-rust-mode
  :ensure t
  :when (bound-and-true-p module-file-suffix)
  :hook ((emacs-lisp-mode
          clojure-mode
          scheme-mode
          lisp-mode) . parinfer-rust-mode)
  :init
  (setq parinfer-rust-disable-troublesome-modes t))

;;; File templates (doom editor/file-templates, simplified)
(leaf autoinsert
  :ensure nil
  :demand t
  :config
  (auto-insert-mode 1)
  (setq auto-insert-query nil)
  (setq auto-insert-alist
        (append
         '((("\\.el\\'" . "Emacs Lisp header") nil
            ";;; " (file-name-nondirectory buffer-file-name) " --- "
            (or (ignore-errors (upcase (file-name-base buffer-file-name))) "")
            "  -*- lexical-binding: t; -*-" "\n\n"
            ";;; " (file-name-nondirectory buffer-file-name) " ends here" "\n"))
         auto-insert-alist)))

;;; Undo (doom emacs/undo, kept here)
(leaf undo-fu
  :ensure t
  :demand t
  :after evil
  :config
  (evil-set-undo-system 'undo-fu))

(leaf undo-fu-session
  :ensure t
  :demand t
  :after undo-fu
  :config
  (undo-fu-session-global-mode 1)
  (setq undo-fu-session-incompatible-files '("/COMMIT_EDITMSG$" "/git-rebase-todo$")))

;;; editor-config.el ends here
(provide 'editor-config)
