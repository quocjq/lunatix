;;; tools/pass.el --- doom tools/pass port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/tools/pass. Uses the lunatix-doom compat layer.
;;; Code:

(leaf password-store
  :ensure t
  :bind ("C-c p" . password-store-copy))

(leaf pass
  :ensure t
  :defer t
  :config
  (when (fboundp 'set-evil-initial-state!)
    (set-evil-initial-state! 'pass-mode 'normal))
  (evil-define-key 'normal pass-mode-map
    "j"   #'pass-next-entry
    "k"   #'pass-prev-entry
    "d"   #'pass-kill
    (kbd "C-j") #'pass-next-directory
    (kbd "C-k") #'pass-prev-directory))

(leaf password-store-otp
  :ensure t
  :defer t
  :after password-store)

(after! evil-collection-pass
  (add-to-list 'evil-collection-pass-command-to-label '(pass-update-buffer . "gr")))

;; `+auth' flag not enabled; `auth-source-pass-enable' dropped.

;;
;;; tools/pdf

;;; tools/pass.el ends here
