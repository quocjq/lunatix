;;; personal.el --- personal info + global defaults  -*- lexical-binding: t; -*-
;;; (migrated from live doom config.org: Basic / Personal Information / Evil-mode)

;;; Runtime state → cache dir, never in the config tree
;; (lunaris-cache-dir defined in lunaris.el)
(setq recentf-save-file (expand-file-name "recentf" lunaris-cache-dir)
      project-list-file (expand-file-name "projects" lunaris-cache-dir)
      pcache-directory (expand-file-name "pcache" lunaris-cache-dir)
      lsp-session-file (expand-file-name "lsp-session-v1" lunaris-cache-dir)
      parinfer-rust-library-dir (expand-file-name "parinfer-rust" lunaris-cache-dir)
      undo-fu-session-directory (expand-file-name "undo-fu-session" lunaris-cache-dir)
      transient-history-file (expand-file-name "transient/history.el" lunaris-cache-dir)
      transient-level-file (expand-file-name "transient/levels.el" lunaris-cache-dir)
      savehist-file (expand-file-name "savehist" lunaris-cache-dir)
      bookmark-default-file (expand-file-name "bookmarks" lunaris-cache-dir)
      elfeed-db-directory (expand-file-name "elfeed" lunaris-cache-dir)
      auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-save/" lunaris-cache-dir) t))
      backup-directory-alist
      `((".*" . ,(expand-file-name "backup/" lunaris-cache-dir)))
      auto-save-list-file-prefix
      (expand-file-name "auto-save-list/.saves-" lunaris-cache-dir))
(make-directory lunaris-cache-dir t)
(dolist (sub '("auto-save" "backup" "transient" "undo-fu-session" "elfeed" "pcache" "url"))
  (make-directory (expand-file-name sub lunaris-cache-dir) t))

;; packages reset their file vars on load; re-apply after they load
(after! transient
  (setq transient-history-file (expand-file-name "transient/history.el" lunaris-cache-dir)
        transient-level-file (expand-file-name "transient/levels.el" lunaris-cache-dir)))
;; projectile cache lives in the emacs dir under project/<username>/, so each
;; user gets their own cache next to the config. Dir is created on demand.
(defvar lunatix-projectile-cache-dir
  (expand-file-name
   (format "project/%s/" (or (user-login-name) (getenv "USER") "user"))
   lunatix-emacs-dir))
(make-directory lunatix-projectile-cache-dir t)
(after! projectile
  (setq projectile-bookmarks-file (expand-file-name "projectile-bookmarks.eld" lunatix-projectile-cache-dir)
        projectile-known-projects-file (expand-file-name "projectile-known-projects" lunatix-projectile-cache-dir)
        projectile-frecency-file (expand-file-name "projectile-frecency.eld" lunatix-projectile-cache-dir)))
(setq url-configuration-directory (expand-file-name "url" lunaris-cache-dir))

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

;; Quit instantly — no "modified buffers" / autosave prompt when closing.
;; Unsaved buffer changes are discarded.
(setq confirm-kill-emacs nil)
(defadvice! luna/kill-emacs-no-prompt-a (&rest _)
  :override #'save-buffers-kill-terminal
  (kill-emacs))

;; Display: relative line numbers
(setq display-line-numbers-type 'relative)

;; Evil: emacs mode as the editing mode (live config)
(setq evil-disable-insert-state-bindings t)
(after! evil
  (defalias 'evil-insert-state 'evil-emacs-state))

;; lwf — declarative window layouts (development checkout, load-path)
(let ((lwf-dir (expand-file-name "lwf" (expand-file-name "Proj" (getenv "HOME")))))
  (when (file-directory-p lwf-dir)
    (add-to-list 'load-path lwf-dir)
    (require 'lwf)
    (require 'lwf-pane)
    (require 'lwf-note)))

;;; personal.el ends here
(provide 'personal)
