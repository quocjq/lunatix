;;; ui/deft.el --- doom ui/deft port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/deft.
;;; Code:

;;; deft
(leaf deft
  :ensure t
  :commands deft
  :init
  (setq deft-directory "~/Documents/notes"
        deft-default-extension "org"
        ;; de-couples filename and note title:
        deft-use-filename-as-title nil
        deft-use-filter-string-for-filename t
        ;; disable auto-save
        deft-auto-save-interval -1.0
        ;; converts the filter string into a readable file-name using kebab-case:
        deft-file-naming-rules
        '((noslash . "-")
          (nospace . "-")
          (case-fn . downcase)))
  :config
  (add-to-list 'deft-extensions "tex")
  (add-hook 'deft-mode-hook #'luna-mark-buffer-as-real-h)
  (after! evil (evil-set-initial-state 'deft-mode 'insert)))

;;; ui/deft.el ends here
