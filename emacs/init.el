;;; init.el --- lunatix emacs config  -*- lexical-binding: t; -*-
;;;
;;; Boot: lunaris framework + manifest + module tree. Config side stays clean;
;;; everything else lives in lunaris.el (leaf DSL, doom-compat, loader).

(setq lunatix-emacs-dir
      (file-name-directory (or load-file-name buffer-file-name)))

;; nix profile bins (rg, fd, lsp servers...) — the daemon/frame PATH can be
;; stale (started before `just switch'), which breaks projectile's
;; executable-find-based backend detection. Always add them.
(dolist (dir (list (expand-file-name ".nix-profile/bin" (or (getenv "HOME") ""))
                   (expand-file-name ".local/state/nix/profile/bin" (or (getenv "HOME") ""))
                   (format "/etc/profiles/per-user/%s/bin" (or (getenv "USER") "root"))
                   "/run/current-system/sw/bin"
                   "/nix/var/nix/profiles/default/bin"))
  (when (file-directory-p dir)
    (add-to-list 'exec-path dir)))

;; big GC threshold during init (doom-style), resets to normal after startup
(setq gc-cons-threshold (* 100 1024 1024))

;; must be set before evil.el is ever loaded (any :after evil forces it early)
(setq evil-want-keybinding nil
      evil-want-C-i-jump nil
      evil-want-C-u-scroll t
      evil-want-Y-yank-to-eol t)

(add-to-list 'load-path (expand-file-name "config" lunatix-emacs-dir))

;; unified backend: leaf DSL + doom-compat + manifest + tree loader
(load (expand-file-name "lunaris.el" lunatix-emacs-dir))

(require 'use-package)
(setq use-package-verbose nil
      ;; doom-style: declare everything, load on demand
      use-package-always-defer t
      ;; nix builds every :ensure package; never let use-package touch
      ;; package.el (no network, no ~/.emacs.d/elpa). Missing packages then
      ;; fail loudly at `require`, not via a silent archive lookup.
      use-package-ensure-function (lambda (&rest _) nil))

;; nix puts every package dir on =load-path= but does not run the autoloads.
;; Register them so autoload-only entry points (e.g. doom-themes-org-config)
;; resolve. Loading = registering; cheap.
(dolist (dir load-path)
  (when (file-directory-p dir)
    (dolist (autoload-file (directory-files dir t "-autoloads\\.el$"))
      (load autoload-file))))

;; enabled-modules declaration (drives `modulep!', documents the set)
(load (expand-file-name "manifest.el" lunatix-emacs-dir))

;; stage 1: load only the dashboard-ready core (identity + keys); the rest of
;; the module tree loads in stage 2 (idle timer below).
(lunaris-load-core (expand-file-name "config" lunatix-emacs-dir))

;; stage-2 commands usable before their module loads (e.g. SPC o d right after
;; startup). ui-config is byte-compiled into the cache. APPEND so the cache's
;; source copies of modules (present while compiling) can't shadow same-named
;; package files on load-path (e.g. php.el, latex.el) — that caused eager
;; macro-expansion to reload our own module -> "skipped due to cycle".
(add-to-list 'load-path (expand-file-name "lisp" lunaris-cache-dir) 'append)
;; absolute path: feature "dashboard" is also the dashboard package's feature,
;; so a bare autoload would resolve to the package instead of our module
(autoload '+dashboard/open
  (expand-file-name "framework/ui/dashboard" lunatix-emacs-dir) nil t)

;; doom :config default-like globals
(setq-default indent-tabs-mode nil
              truncate-lines t)
(global-display-line-numbers-mode 1)

;; doom :ui default chrome — no menu/tool/scroll bars, clean frame title
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(tab-bar-mode -1)
(setq frame-title-format '("%b" . "emacs"))

;; Dashboard first (stage 1): the frame opens on the *doom* buffer; ui-config
;; (stage 2) renders its widgets into it.
(setq initial-buffer-choice (lambda () (get-buffer-create "*doom*")))

;; Stage 2: load common packages in the background once the frame is idle
;; (dashboard/frame render = stage 1, packages = stage 2).
(run-with-idle-timer 2 nil #'lunaris-stage-2)

;; settle GC back to a sane threshold after startup
(run-with-idle-timer 5 nil
  (lambda ()
    (setq gc-cons-threshold (* 20 1024 1024)
          gc-cons-percentage 0.6)))

(provide 'init)
;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ignored-local-variable-values '((eval progn (pp-buffer) (indent-buffer)))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-document-title ((t (:height 1.5))))
 '(outline-1 ((t (:weight extra-bold :height 1.3))))
 '(outline-2 ((t (:weight bold :height 1.25))))
 '(outline-3 ((t (:weight bold :height 1.15))))
 '(outline-4 ((t (:weight semi-bold :height 1.09))))
 '(outline-5 ((t (:weight semi-bold :height 1.06))))
 '(outline-6 ((t (:weight semi-bold :height 1.03))))
 '(outline-8 ((t (:weight semi-bold))))
 '(outline-9 ((t (:weight semi-bold)))))
