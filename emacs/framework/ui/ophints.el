;;; ui/ophints.el --- doom ui/ophints port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/ophints.
;;; Code:

;;; :ui ophints
(leaf evil-goggles
  :ensure t
  :defer t
  :after evil
  :init
  (setq evil-goggles-duration 0.1
        evil-goggles-pulse nil ; too slow
        ;; evil-goggles provides a good indicator of what has been affected.
        ;; delete/change is obvious, so I'd rather disable it for these.
        evil-goggles-enable-delete nil
        evil-goggles-enable-change nil)
  :config
  (evil-goggles-mode 1)
  ;; The lispyville (+editor lispy) commands aren't enabled, so they're
  ;; omitted; the doom-only `+evil:yank-unindented'/`+eval:region' entries are
  ;; kept (harmless if their commands don't exist).
  (dolist (cmd `((evil-magit-yank-whole-line
                  :face evil-goggles-yank-face
                  :switch evil-goggles-enable-yank
                  :advice evil-goggles--generic-async-advice)
                 (+evil:yank-unindented
                  :face evil-goggles-yank-face
                  :switch evil-goggles-enable-yank
                  :advice evil-goggles--generic-async-advice)
                 (+eval:region
                  :face evil-goggles-yank-face
                  :switch evil-goggles-enable-yank
                  :advice evil-goggles--generic-async-advice)))
    (add-to-list 'evil-goggles--commands cmd)))

;;; ui/ophints.el ends here
