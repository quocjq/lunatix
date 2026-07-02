(setq doom-theme 'doom-monokai-octagon)
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 20 :weight 'medium))
(add-hook 'window-setup-hook #'toggle-frame-maximized)
(setq display-line-numbers-type 'relative)
(setq org-directory "~/org/")

(defun my/tabout ()
  (interactive)
  (cond
   ((and (derived-mode-p 'org-mode)
         (fboundp 'org-at-table-p)
         (org-at-table-p))
    (call-interactively #'org-cycle))
   (t
    (ignore-errors (sp-up-sexp)))))
(map! :i "TAB" #'my/tabout)

(with-eval-after-load 'org (global-org-modern-mode))
