;;; lang/rust.el --- doom lang/rust port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/rust.
;;; Code:

;;; -- rust helpers (autoload/rust.el) ---------------------------------------

(defun +rust-cargo-project-p ()
  "Return t if this is a cargo project."
  (locate-dominating-file buffer-file-name "Cargo.toml"))

(autoload 'rustic-run-cargo-command "rustic-cargo")
(defun +rust/cargo-audit ()
  "Run 'cargo audit' for the current project."
  (interactive)
  (rustic-run-cargo-command "cargo audit"))

;;; ===================================================================
;;; :lang go
;;; ===================================================================

(defun +go-common-config (mode)
  (when (modulep! +lsp)
    (add-hook (intern (format "%s-hook" mode)) #'lsp-deferred)))

(leaf go-mode
  :ensure t
  :config
  (+go-common-config 'go-mode))

(leaf go-ts-mode ; 29.1+ only
  :ensure nil
  :when (modulep! +tree-sitter)
  :mode ("/go\\.mod\\'" . go-mod-ts-mode-maybe)
  :config
  (+go-common-config 'go-ts-mode))

(leaf go-tag
  :ensure t
  :commands (go-tag-add go-tag-remove))

(leaf go-gen-test
  :ensure t
  :commands (go-gen-test-dwim go-gen-test-all go-gen-test-exported))

(leaf gorepl-mode
  :ensure t
  :commands gorepl-run-load-current-file)

;;; lang/rust.el ends here