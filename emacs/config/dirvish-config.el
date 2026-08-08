;;; dirvish-config.el --- doom :emacs dired +dirvish  -*- lexical-binding: t; -*-

(leaf dired
  :ensure nil
  :commands dired-jump
  :config
  (setq dired-dwim-target t
        dired-auto-revert-buffer #'dired-buffer-stale-p
        dired-recursive-copies 'always
        dired-recursive-deletes 'top
        dired-create-destination-dirs 'ask
        image-dired-dir (luna-profile-cache-dir "image-dired/")
        image-dired-db-file (concat image-dired-dir "db.el")
        image-dired-gallery-dir (concat image-dired-dir "gallery/")
        image-dired-temp-image-file (concat image-dired-dir "temp-image")
        image-dired-temp-rotate-image-file (concat image-dired-dir "temp-rotate-image")
        image-dired-thumb-size 150)
  (after! evil
    (evil-set-initial-state 'image-dired-display-image-mode 'emacs))
  (setq dired-listing-switches "-ahl -v --time-style=long-iso --group-directories-first")
  (add-hook 'dired-mode-hook
            (lambda ()
              (when (or (file-remote-p default-directory)
                        (and (boundp 'ls-lisp-use-insert-directory-program)
                             (not ls-lisp-use-insert-directory-program)))
                (setq-local dired-actual-switches "-alh"))))
  (put 'dired-find-alternate-file 'disabled nil)
  ;; force details ON (dirvish enables hide-details; size/date must show)
  (add-hook 'dired-mode-hook (lambda () (dired-hide-details-mode -1)))
  ;; dirvish-override resets the listing; re-apply date + size columns
  (after! dirvish
    (setq dired-listing-switches "-ahl -v --time-style=long-iso --group-directories-first")))

(leaf dirvish
  :ensure t
  :commands (dirvish-dired-noselect-a dirvish--find-entry)
  :config
  (setq dirvish-cache-dir (file-name-concat (luna-profile-cache-dir) "dirvish/")
        dirvish-reuse-session 'open
        dirvish-attributes '(file-size)
        dirvish-mode-line-format
        '(:left (sort file-time symlink) :right (omit yank index)))
  (advice-add #'dired--find-file :override #'dirvish--find-entry)
  (advice-add #'dired-noselect :around #'dirvish-dired-noselect-a)
  (dirvish-override-dired-mode)
  ;; dirvish replaces the dired keymap; re-apply evil-collection's dired binds
  (after! evil-collection-dired
    (evil-collection-dired-setup))
)

;;; dirvish.el ends here
(provide 'dirvish-config)
