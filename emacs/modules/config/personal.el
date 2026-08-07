;;; personal.el --- personal info + global defaults (migrated from live
;;; doom config.org: Basic / Personal Information / Evil-mode)  -*- lexical-binding: t; -*-

;;; Runtime state → cache dir, never in the config tree
(defvar lunaris-cache-dir (doom-profile-cache-dir)
  "Directory for all runtime state (recentf, pcache, lsp session, libs).")

(setq recentf-save-file (expand-file-name "recentf" lunaris-cache-dir)
      project-list-file (expand-file-name "projects" lunaris-cache-dir)
      pcache-directory (expand-file-name "pcache" lunaris-cache-dir)
      lsp-session-file (expand-file-name "lsp-session-v1" lunaris-cache-dir)
      parinfer-rust-library-dir (expand-file-name "parinfer-rust" lunaris-cache-dir))

(setq user-full-name "Lunixose"
      user-mail-address "luniose@gmail.com")

;; Better defaults
(setq-default delete-by-moving-to-trash t
              window-combination-resize t
              x-stretch-cursor t)
(setq undo-limit (* 80 1024 1024)     ; 80 MB undo
      evil-want-fine-undo t
      truncate-string-ellipsis "…"
      password-cache-expiry nil
      display-time-default-load-average nil
      which-key-idle-delay 0.4)
(display-time-mode 1)
(global-subword-mode 1)

;; Editing defaults: 2-space indent, no auto-save files
(setq-default tab-width 2)
(setq-default evil-shift-width 2)
(setq auto-save-default nil)

;; Buffer behavior: auto-revert
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)

;; Display: relative line numbers
(setq display-line-numbers-type 'relative)

;; Evil: emacs mode as the editing mode (live config)
(setq evil-disable-insert-state-bindings t)
(after! evil
  (defalias 'evil-insert-state 'evil-emacs-state)
  (define-key evil-emacs-state-map (kbd "<escape>") 'evil-normal-state)
  (define-key evil-emacs-state-map (kbd "C-g") 'evil-normal-state))

;;; personal.el ends here
(provide 'personal)
