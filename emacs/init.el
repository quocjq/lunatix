;;; init.el --- lunatix emacs config  -*- lexical-binding: t; -*-
;;;
;;; Boot: lunaris framework + manifest + module tree. Config side stays clean;
;;; everything else lives in lunaris.el (leaf DSL, doom-compat, loader).

(setq lunatix-emacs-dir
      (file-name-directory (or load-file-name buffer-file-name)))

;; must be set before evil.el is ever loaded (any :after evil forces it early)
(setq evil-want-keybinding nil)

(add-to-list 'load-path (expand-file-name "modules" lunatix-emacs-dir))

;; unified backend: leaf DSL + doom-compat + manifest + tree loader
(load (expand-file-name "lunaris.el" lunatix-emacs-dir))

(require 'use-package)
(setq use-package-verbose t
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

;; load the module tree (modules/**/*.el, `_`-prefixed skipped)
(lunaris-load-tree (expand-file-name "modules" lunatix-emacs-dir))

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

;; Stage 2: load common packages in the background once the frame is idle
;; (dashboard/frame render = stage 1, packages = stage 2).
(run-with-idle-timer 2 nil #'lunaris-stage-2)

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
