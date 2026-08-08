;;; ui/modeline.el --- doom ui/modeline port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/modeline.
;;; Code:

;;; :ui modeline
(leaf doom-modeline
  :ensure t
  :defer t
  :hook (doom-modeline-mode . size-indication-mode) ; filesize in modeline
  :hook (doom-modeline-mode . column-number-mode)   ; cursor column in modeline
  :init
  ;; We display project info in the modeline ourselves
  (setq projectile-dynamic-mode-line nil)
  ;; Set these early so they don't trigger variable watchers
  (setq doom-modeline-bar-width 3
        doom-modeline-github nil
        doom-modeline-mu4e nil
        doom-modeline-persp-name nil
        doom-modeline-minor-modes nil
        doom-modeline-major-mode-icon nil
        doom-modeline-check 'simple  ; default is too busy
        doom-modeline-buffer-file-name-style 'relative-from-project
        ;; Only show file encoding if it's non-UTF-8 and different line
        ;; endings than the current OSes preference
        doom-modeline-buffer-encoding 'nondefault
        doom-modeline-default-eol-type (if (eq system-type 'windows-nt) 1 0))
  :config
  (doom-modeline-mode 1)

  ;; Fix an issue where these two variables aren't defined in TTY Emacs on
  ;; MacOS
  (defvar mouse-wheel-down-event nil)
  (defvar mouse-wheel-up-event nil)

  ;; doom's `+modeline-resize-for-font-h' hooks `after-setting-font-hook' and
  ;; uses `doom-font-increment' -- both doom-core (not ported); dropped.
  (add-hook 'luna-load-theme-hook #'doom-modeline-refresh-bars)

  (add-to-list 'doom-modeline-mode-alist '(+dashboard-mode . dashboard))
  ;; APROX: anzu/evil-anzu (isearch counts) aren't in this config's package
  ;; set; dropped.

  ;; Show minimal modeline in magit-status buffer, no modeline elsewhere.
  (defun +modeline-hide-in-non-status-buffer-h ()
    (if (eq major-mode 'magit-status-mode)
        (doom-modeline-set-modeline 'magit)
      ;; doom's `mode-line-invisible-mode' isn't available outside doom core
      (setq-local mode-line-format nil)))
  (add-hook 'magit-mode-hook #'+modeline-hide-in-non-status-buffer-h))

;;; ui/modeline.el ends here
