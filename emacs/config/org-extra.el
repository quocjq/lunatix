;;; org-extra.el --- org visual + behaviour + agenda (live config.org Languages/Orgmode)  -*- lexical-binding: t; -*-

;;; Org directory
(setq org-directory (expand-file-name "~/Documents/notes/"))

;;; Appearance — org-modern
(leaf org-modern
  :ensure t
  :demand t
  :config
  (setq org-modern-star 'replace
        org-modern-list '((?- . "•") (?+ . "◦") (?* . "▪"))
        org-modern-block-fringe 15
        org-modern-table t
        org-modern-timestamp t)
  (setq org-ellipsis " ▾"
        org-pretty-entities t
        org-hide-emphasis-markers t)
  (global-org-modern-mode))

;;; Appearance — org-appear (restore emphasis markers while editing)
(leaf org-appear
  :ensure t
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-autoemphasis t
        org-appear-autolinks t
        org-appear-autosubmarkers t
        org-appear-trigger 'manual)
  (add-hook 'org-mode-hook
            (lambda ()
              (add-hook 'evil-emacs-state-entry-hook #'org-appear-manual-start nil t)
              (add-hook 'evil-emacs-state-exit-hook #'org-appear-manual-stop nil t))))

;;; Fonts and headings
(custom-set-faces
 '(outline-1 ((t (:weight extra-bold :height 1.3))))
 '(outline-2 ((t (:weight bold :height 1.25))))
 '(outline-3 ((t (:weight bold :height 1.15))))
 '(outline-4 ((t (:weight semi-bold :height 1.09))))
 '(outline-5 ((t (:weight semi-bold :height 1.06))))
 '(outline-6 ((t (:weight semi-bold :height 1.03))))
 '(outline-8 ((t (:weight semi-bold))))
 '(outline-9 ((t (:weight semi-bold))))
 '(org-document-title ((t (:height 1.5)))))

;;; Behaviour
(after! org
  (setq org-log-done 'time
        org-startup-folded 'content
        org-startup-indented t
        org-hide-leading-stars t
        org-return-follows-link t
        org-use-property-inheritance t
        org-list-allow-alphabetical t
        org-catch-invisible-edits 'smart
        org-export-with-sub-superscripts '{}
        org-image-actual-width '(0.9)
        org-fontify-quote-and-verse-blocks t
        org-agenda-deadline-faces
        '((1.001 . error)
          (1.0 . org-warning)
          (0.5 . org-upcoming-deadline)
          (0.0 . org-upcoming-distant-deadline))))

;; hard-wrap text buffers (auto-fill) instead of visual-line
(remove-hook 'text-mode-hook #'visual-line-mode)
(add-hook 'text-mode-hook #'auto-fill-mode)

;;; Auto-align tables — org-modern/org-appear change display widths (autohide,
;;; emphasis markers) and native org realign misses those. Align when the
;;; buffer changed or the cursor entered a different table row.
(defvar-local +org--align-tick 0)
(defvar-local +org--align-row -1)

(defun +org/align-current-table-h ()
  (when-let* ((row (and (org-at-table-p) (org-table-current-line))))
    (when (or (/= (buffer-chars-modified-tick) +org--align-tick)
              (/= row +org--align-row))
      (setq +org--align-tick (buffer-chars-modified-tick)
            +org--align-row row)
      (org-table-align))))

(add-hook 'org-mode-hook
          (lambda ()
            (add-hook 'post-command-hook #'+org/align-current-table-h nil t)))

;; also realign after backspace inside a table
(defun +org-delete-backward-and-realign-table-h ()
  (when (org-at-table-p)
    (org-table-align)))

(add-hook 'org-mode-hook
          (lambda ()
            (add-hook 'delete-backward-char-functions
                      #'+org-delete-backward-and-realign-table-h nil t)))

;;; Agenda — org-super-agenda + custom "o" Overview command (tecosaur)
(leaf org-super-agenda
  :ensure t
  :demand t
  :config
  (let ((inhibit-message t))
    (org-super-agenda-mode))
  (setq org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-agenda-include-deadlines t
        org-agenda-block-separator nil
        org-agenda-tags-column 100
        org-agenda-compact-blocks t)
  (setq org-agenda-custom-commands
        '(("o" "Overview"
           ((agenda "" ((org-agenda-span 'day)
                        (org-super-agenda-groups
                         '((:name "Today"
                            :time-grid t
                            :date today
                            :todo "TODAY"
                            :scheduled today
                            :order 1)))))
            (alltodo "" ((org-agenda-overriding-header "")
                         (org-super-agenda-groups
                          '((:name "Next to do" :todo "NEXT" :order 1)
                            (:name "Important" :tag "Important" :priority "A" :order 6)
                            (:name "Due Today" :deadline today :order 2)
                            (:name "Due Soon" :deadline future :order 8)
                            (:name "Overdue" :deadline past :face error :order 7)
                            (:name "Assignments" :tag "Assignment" :order 10)
                            (:name "Issues" :tag "Issue" :order 12)
                            (:name "Emacs" :tag "Emacs" :order 13)
                            (:name "Projects" :tag "Project" :order 14)
                            (:name "Research" :tag "Research" :order 15)
                            (:name "To read" :tag "Read" :order 30)
                            (:name "Waiting" :todo "WAITING" :order 20)
                            (:name "University" :tag "uni" :order 32)
                            (:name "Trivial"
                             :priority<= "E"
                             :tag ("Trivial" "Unimportant")
                             :todo ("SOMEDAY")
                             :order 90)
                            (:discard (:tag ("Chore" "Routine" "Daily"))))))))))))

;;; org-extra.el ends here
(provide 'org-extra)
