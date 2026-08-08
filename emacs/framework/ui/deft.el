;;; ui/deft.el --- doom ui/deft port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/deft.
;;; Code:

;;; deft
(leaf deft
  :ensure t
  :commands deft
  :bind ("C-c d" . deft)
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
  (after! evil (evil-set-initial-state 'deft-mode 'insert))
  (map! :map deft-mode-map
        :n "gr"  #'deft-refresh
        :n "C-s" #'deft-filter
        :i "C-n" #'deft-new-file
        :i "C-m" #'deft-new-file-named
        :i "C-d" #'deft-delete-file
        :i "C-r" #'deft-rename-file
        :n "r"   #'deft-rename-file
        :n "a"   #'deft-new-file
        :n "A"   #'deft-new-file-named
        :n "d"   #'deft-delete-file
        :n "D"   #'deft-archive-file
        :n "q"   #'kill-current-buffer)
  ;; APROX: doom's `:localleader' isn't in the compat map!; bind the prefix
  ;; directly with general-def. Wrapped: deft-mode-map already binds SPC, so
  ;; the "SPC m" prefix define-key errors on some states.
  (condition-case nil
      (general-def :keymaps 'deft-mode-map :prefix luna-localleader-key
        "RET" #'deft-new-file-named
        "a"   #'deft-archive-file
        "c"   #'deft-filter-clear
        "d"   #'deft-delete-file
        "f"   #'deft-find-file
        "g"   #'deft-refresh
        "l"   #'deft-filter
        "n"   #'deft-new-file
        "r"   #'deft-rename-file
        "s"   #'deft-toggle-sort-method
        "t"   #'deft-toggle-incremental-search)
    (error nil)))

;;; ui/deft.el ends here
