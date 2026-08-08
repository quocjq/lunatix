;;; denote-config.el --- note-taking suite (live config.org Note-taking)  -*- lexical-binding: t; -*-

(leaf denote
  :ensure t
  :hook ((text-mode . denote-fontify-links-mode)
         (dired-mode . denote-dired-mode))
  :config
  (setq denote-directory (expand-file-name "~/Documents/notes/")
        denote-save-buffers nil
        denote-known-keywords '("emacs" "nixos" "personal" "learning"
                                "thinking" "philosophy" "politics" "economics")
        denote-infer-keywords t
        denote-sort-keywords t
        denote-prompts '(title keywords)
        denote-excluded-directories-regexp nil
        denote-keywords-to-not-infer-regexp nil
        denote-rename-confirmations '(rewrite-front-matter modify-file-name)
        denote-date-prompt-use-org-read-date t)
  (denote-rename-buffer-mode 1))

(leaf denote-sequence
  :ensure t
  :after denote
  :config
  (setq denote-sequence-scheme 'alphanumeric))

(leaf denote-journal
  :ensure t
  :after denote
  :commands (denote-journal-new-entry
             denote-journal-new-or-existing-entry
             denote-journal-link-or-create-entry)
  :hook (calendar-mode . denote-journal-calendar-mode)
  :config
  (setq denote-journal-directory (expand-file-name "journal" denote-directory)
        denote-journal-keyword "journal"
        denote-journal-title-format 'day-date-month-year))

(leaf consult-denote
  :ensure t
  :after denote
  :config
  (consult-denote-mode 1)
  (setq consult-denote-grep-command #'consult-ripgrep))

;; SPC e — Notes (denote)
(after! denote
  (lunatix-leader
    "e"   '("Notes (denote)")
    "en"  #'denote
    "ef"  #'consult-denote-find
    "eg"  #'consult-denote-grep
    "el"  #'denote-link
    "eL"  #'denote-add-links
    "eb"  #'denote-backlinks
    "er"  #'denote-rename-file
    "eR"  #'denote-rename-file-using-front-matter
    "eqc" #'denote-query-contents-link
    "eqf" #'denote-query-filenames-link
    "edd" #'denote-dired
    "edi" #'denote-dired-link-marked-notes
    "edr" #'denote-dired-rename-files
    "edk" #'denote-dired-rename-marked-files-with-keywords
    "edR" #'denote-dired-rename-marked-files-using-front-matter
    "ess" #'denote-sequence
    "esf" #'denote-sequence-find
    "esl" #'denote-sequence-link
    "esd" #'denote-sequence-dired
    "ejj" #'denote-journal-new-entry
    "ejo" #'denote-journal-new-or-existing-entry
    "ejl" #'denote-journal-link-or-create-entry))

;;; denote.el ends here
(provide 'denote-config)
