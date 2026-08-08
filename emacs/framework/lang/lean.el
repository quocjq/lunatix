;;; lang/lean.el --- doom lang/lean port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/lean.
;;; Code:

;;; lang/lean
;; lean-mode (+v3): not packaged in nixpkgs; dropped.
(leaf nael
  :ensure t
  :init
  (add-hook 'nael-mode-hook #'abbrev-mode)
  (with-eval-after-load 'org-src
    (add-to-list 'org-src-lang-modes '("lean" . nael)))
  (with-eval-after-load 'markdown-mode
    (add-to-list 'markdown-code-lang-modes '("lean" . nael-mode)))
  :config
  (sp-with-modes 'nael-mode
    (sp-local-pair "/-" "-/")
    (sp-local-pair "`" "`")
    (sp-local-pair "{" "}")
    (sp-local-pair "«" "»")
    (sp-local-pair "⟨" "⟩")
    (sp-local-pair "⟪" "⟫"))
  (general-def :keymaps 'nael-mode-map :prefix luna-localleader-key
    "a" #'nael-abbrev-help
    "b" #'project-build
    "e" #'eldoc-doc-buffer))
;; nael lsp wiring (`nael-prepare-lsp'/`lsp!') is gated on `+lsp` (nil in
;; compat); dropped.

;;; lang/lean.el ends here