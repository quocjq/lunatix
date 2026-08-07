;;; editor-extra.el --- snippets + tabout tweaks (live config.org)  -*- lexical-binding: t; -*-

;; YASnippet: nested expansion + personal snippet dir
(after! yasnippet
  (setq yas-triggers-in-field t)
  (let ((dir (expand-file-name "snippets" (doom-user-dir))))
    (when (file-directory-p dir)
      (add-to-list 'yas-snippet-dirs dir))))

;; Tab-out (lnav) — github-only, not in nixpkgs; skipped.
;;; editor-extra.el ends here
(provide 'editor-extra)
