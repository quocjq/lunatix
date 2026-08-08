;;; tools/biblio.el --- doom tools/biblio port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/tools/biblio. Uses the lunatix-doom compat layer.
;;; Code:

;;; tools/biblio

(after! oc
  (setq org-cite-global-bibliography
        (ensure-list
         (or (bound-and-true-p citar-bibliography)
             (bound-and-true-p bibtex-completion-bibliography)))
        org-cite-export-processors '((latex biblatex) (t csl))
        org-support-shift-select t)
  (require 'oc-biblatex))

(after! org (require 'oc-csl))

(leaf biblio
  :ensure t
  :defer t)

(leaf citar
  :ensure t
  :defer t
  :init
  (setq org-cite-insert-processor 'citar
        org-cite-follow-processor 'citar
        org-cite-activate-processor 'citar)
  :config
  (when (modulep! :completion vertico +icons)
    (defvar citar-indicator-files-icons
      (citar-indicator-create
       :symbol (nerd-icons-faicon
                "nf-fa-file_o"
                :face 'nerd-icons-green
                :v-adjust -0.1)
       :function #'citar-has-files
       :padding "  "
       :tag "has:files"))
    (defvar citar-indicator-links-icons
      (citar-indicator-create
       :symbol (nerd-icons-faicon
                "nf-fa-link"
                :face 'nerd-icons-orange
                :v-adjust 0.01)
       :function #'citar-has-links
       :padding "  "
       :tag "has:links"))
    (defvar citar-indicator-notes-icons
      (citar-indicator-create
       :symbol (nerd-icons-codicon
                "nf-cod-note"
                :face 'nerd-icons-blue
                :v-adjust -0.3)
       :function #'citar-has-notes
       :padding "    "
       :tag "has:notes"))
    (defvar citar-indicator-cited-icons
      (citar-indicator-create
       :symbol (nerd-icons-faicon
                "nf-fa-circle_o"
                :face 'nerd-icon-green)
       :function #'citar-is-cited
       :padding "  "
       :tag "is:cited"))
    (setq citar-indicators
          (list citar-indicator-files-icons
                citar-indicator-links-icons
                citar-indicator-notes-icons
                citar-indicator-cited-icons))))

(leaf citar-embark
  :ensure t
  :after (citar embark)
  :defer t
  :config
  (citar-embark-mode))

(leaf embark
  :ensure t
  :defer t
  :config
  (setq prefix-help-command #'embark-prefix-help-command))

(leaf embark-consult
  :ensure t
  :after (embark consult)
  :defer t)

;; citar-org-roam: only for `:lang org +roam', not ported.  Dropped.

;;

;;; tools/biblio.el ends here
