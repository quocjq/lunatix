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
    (add-hook (intern (format "%s-hook" mode)) #'lsp-deferred))
  (let ((map (intern (format "%s-map" mode))))
    (general-define-key
     :keymaps map :states '(normal visual motion)
     :prefix luna-localleader-key
     "a" '(go-tag-add :wk "add struct tags")
     "d" '(go-tag-remove :wk "remove struct tags")
     "e" '(#'+go/play-buffer-or-region :wk "play buffer/region")
     "i" '(go-goto-imports :wk "go to imports")
     "h." '(godoc-at-point :wk "godoc at point")
     "ria" '(go-import-add :wk "add import")
     "br" '(cmd! (compile "go run .") :wk "go run .")
     "bb" '(cmd! (compile "go build") :wk "go build")
     "bc" '(cmd! (compile "go clean") :wk "go clean")
     "gf" '(#'+go/generate-file :wk "go generate file")
     "gd" '(#'+go/generate-dir :wk "go generate dir")
     "ga" '(#'+go/generate-all :wk "go generate all")
     "tt" '(#'+go/test-rerun :wk "rerun last test")
     "ta" '(#'+go/test-all :wk "test all")
     "ts" '(#'+go/test-single :wk "test single")
     "tn" '(#'+go/test-nested :wk "test nested")
     "tf" '(#'+go/test-file :wk "test file")
     "tg" '(go-gen-test-dwim :wk "gen test dwim")
     "tG" '(go-gen-test-all :wk "gen test all")
     "te" '(go-gen-test-exported :wk "gen test exported")
     "tbs" '(#'+go/bench-single :wk "bench single")
     "tba" '(#'+go/bench-all :wk "bench all"))))

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