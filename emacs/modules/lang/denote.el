;;; denote.el --- note-taking suite (live config.org Note-taking)  -*- lexical-binding: t; -*-

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
(map! :leader
      (:prefix ("e" . "Notes (denote)")
       "n"   #'denote
       "f"   #'consult-denote-find
       "g"   #'consult-denote-grep
       "l"   #'denote-link
       "L"   #'denote-add-links
       "b"   #'denote-backlinks
       "r"   #'denote-rename-file
       "R"   #'denote-rename-file-using-front-matter
       (:prefix ("q" . "Query")
        "c"   #'denote-query-contents-link
        "f"   #'denote-query-filenames-link)
       (:prefix ("d" . "Dired")
        "d"   #'denote-dired
        "i"   #'denote-dired-link-marked-notes
        "r"   #'denote-dired-rename-files
        "k"   #'denote-dired-rename-marked-files-with-keywords
        "R"   #'denote-dired-rename-marked-files-using-front-matter)
       (:prefix ("s" . "Sequence")
        "s"   #'denote-sequence
        "f"   #'denote-sequence-find
        "l"   #'denote-sequence-link
        "d"   #'denote-sequence-dired)
       (:prefix ("j" . "Journal")
        "j"   #'denote-journal-new-entry
        "o"   #'denote-journal-new-or-existing-entry
        "l"   #'denote-journal-link-or-create-entry)))

;;; denote.el ends here
(provide 'denote)
