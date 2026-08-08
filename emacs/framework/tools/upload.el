;;; tools/upload.el --- doom tools/upload port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/tools/upload. Uses the lunatix-doom compat layer.
;;; Code:

(leaf ssh-deploy
  :ensure t
  :commands (ssh-deploy-upload-handler
             ssh-deploy-upload-handler-forced
             ssh-deploy-diff-handler
             ssh-deploy-browse-remote-handler
             ssh-deploy-remote-changes-handler)
  :init
  (setq ssh-deploy-revision-folder (file-name-concat luna-cache-dir "ssh-revisions/")
        ssh-deploy-on-explicit-save 1
        ssh-deploy-automatically-detect-remote-changes nil)

  ;; Forward-declare these as safe file/dir-local variables in case files set
  ;; them before ssh-deploy is loaded.
  (dolist (sym '((ssh-deploy-root-local . stringp)
                 (ssh-deploy-root-remote . stringp)
                 (ssh-deploy-script . functionp)
                 (ssh-deploy-on-explicit-save . booleanp)
                 (ssh-deploy-force-on-explicit-save . booleanp)
                 (ssh-deploy-async . booleanp)
                 (ssh-deploy-exclude-list . listp)))
    (put (car sym) 'safe-local-variable (cdr sym)))

  ;; Respect `ssh-deploy-on-explicit-save' if `ssh-deploy-root-remote' has
  ;; changed since the buffer was opened.
  (defun +upload-init-after-save-h ()
    (when (and (bound-and-true-p ssh-deploy-root-remote)
               (require 'ssh-deploy nil t)
               (integerp ssh-deploy-on-explicit-save)
               (> ssh-deploy-on-explicit-save 0))
      (ssh-deploy-upload-handler ssh-deploy-force-on-explicit-save)
      (when (or ssh-deploy-root-remote
                ssh-deploy-root-local)
        (ssh-deploy-line-mode +1))))
  (add-hook 'after-save-hook #'+upload-init-after-save-h)

  ;; Enable ssh-deploy if variables are set, and check for changes on open file.
  (defun +upload-init-find-file-h ()
    (when (and (bound-and-true-p ssh-deploy-root-remote)
               (require 'ssh-deploy nil t))
      (unless ssh-deploy-root-local
        (setq ssh-deploy-root-local (luna-project-root)))
      (when ssh-deploy-automatically-detect-remote-changes
        (ssh-deploy-remote-changes-handler))
      (when (or ssh-deploy-root-remote
                ssh-deploy-root-local)
        (ssh-deploy-line-mode +1))))
  (add-hook 'find-file-hook #'+upload-init-find-file-h))

;;; tools/upload.el ends here
