;;; emacs/undo.el --- doom emacs/undo port: evil undo system  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/emacs/undo.
;;; Code:

;;; Evil undo system (doom emacs/undo) — undo-fu gives vim-style u/C-r
;;; (unlimited, branchless) instead of Emacs' ctrl-_ partial-undo.
(leaf undo-fu
  :ensure t
  :defer t
  :after evil
  :init
  (setq evil-undo-system 'undo-fu)
  :config
  (evil-set-undo-system 'undo-fu))

;;; Persistent undo sessions — history survives emacs restarts (undo-fu-session
;;; saves per-file undo state to disk). Sessions land in the XDG cache dir
;;; (see config/personal.el). Files that must not be reverted on open are
;;; excluded: commit/rebase messages should always start fresh.
(leaf undo-fu-session
  :ensure t
  :defer t
  :after undo-fu
  :config
  (undo-fu-session-global-mode 1)
  (setq undo-fu-session-incompatible-files '("/COMMIT_EDITMSG$" "/git-rebase-todo$")))

;;; vundo: visual undo tree on top of the standard undo list (works with
;;; undo-fu, which keeps history in `buffer-undo-list').  Open with `SPC u'.
(leaf vundo
  :ensure t
  :commands vundo)

;;; emacs/undo.el ends here
