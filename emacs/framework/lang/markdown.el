;;; lang/markdown.el --- doom lang/markdown port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/markdown.
;;; Code:

;;; -- markdown helpers (autoload.el) -----------------------------------------

(defun +markdown-compile (beg end output-buffer)
  "Compile markdown into html.

Runs `+markdown-compile-functions' until the first function to return non-nil,
otherwise throws an error."
  (or (run-hook-with-args-until-success '+markdown-compile-functions
                                        beg end output-buffer)
      (user-error "No markdown program could be found. Install marked, pandoc, markdown or multimarkdown.")))

(defun +markdown-compile-marked (beg end output-buffer)
  "Compiles markdown with the marked program, if available.
Returns its exit code."
  (when (executable-find "marked")
    (apply #'call-process-region
           beg end "marked" nil output-buffer nil
           (when (eq major-mode 'gfm-mode)
             (list "--gfm" "--tables" "--breaks")))))

(defun +markdown-compile-pandoc (beg end output-buffer)
  "Compiles markdown with the pandoc program, if available.
Returns its exit code."
  (when (executable-find "pandoc")
    (call-process-region beg end "pandoc" nil output-buffer nil
                         "-f" "markdown"
                         "-t" "html"
                         "--mathjax")))

(defun +markdown-compile-multimarkdown (beg end output-buffer)
  "Compiles markdown with the multimarkdown program, if available. Returns its
exit code."
  (when (executable-find "multimarkdown")
    (call-process-region beg end "multimarkdown" nil output-buffer)))

(defun +markdown-compile-markdown (beg end output-buffer)
  "Compiles markdown using the Markdown.pl script (or markdown executable), if
available. Returns its exit code."
  (when-let* ((exe (or (executable-find "Markdown.pl")
                       (executable-find "markdown"))))
    (call-process-region beg end exe nil output-buffer nil)))

(defun +markdown/insert-del ()
  "Surround region in github strike-through delimiters."
  (interactive)
  (let ((regexp "\\(^\\|[^\\]\\)\\(\\(~\\{2\\}\\)\\([^ \n\t\\]\\|[^ \n\t]\\(?:.\\|\n[^\n]\\)*?[^\\ ]\\)\\(\\3\\)\\)")
        (delim "~~"))
    (if (markdown-use-region-p)
        ;; Active region
        (cl-destructuring-bind (beg . end)
            (markdown-unwrap-things-in-region
             (region-beginning) (region-end)
             regexp 2 4)
          (markdown-wrap-or-insert delim delim nil beg end))
      ;; Bold markup removal, bold word at point, or empty markup insertion
      (if (thing-at-point-looking-at regexp)
          (markdown-unwrap-thing-at-point nil 2 4)
        (markdown-wrap-or-insert delim delim 'word nil nil)))))

;;; ===================================================================
;;; :lang json
;;; ===================================================================

(leaf json-mode
  :ensure t
  :mode "\\.js\\(?:on\\|[hl]int\\(?:rc\\)?\\)\\'"
  :config
  (when (modulep! +lsp)
    (add-hook 'json-mode-hook #'lsp-deferred))
  (general-define-key
   :keymaps 'json-mode-map
   :states '(normal visual motion)
   :prefix luna-localleader-key
   "p" '(json-mode-show-path :wk "show path")
   "t" '(json-toggle-boolean :wk "toggle boolean")
   "d" '(json-mode-kill-path :wk "kill path")
   "x" '(json-nullify-sexp :wk "nullify sexp")
   "+" '(json-increment-number-at-point :wk "increment number")
   "-" '(json-decrement-number-at-point :wk "decrement number")
   "f" '(json-mode-beautify :wk "beautify")))

;;; ===================================================================
;;; :lang yaml
;;; ===================================================================

(leaf yaml-mode
  :ensure t
  :mode "Procfile\\'"
  :config
  (when (modulep! +lsp)
    (add-hook 'yaml-mode-hook #'lsp-deferred))
  ;; HACK: `yaml-ts-mode' doesn't implement any indentation (falling back to
  ;;   `indent-relative'), so borrow `yaml-mode's.
  (add-hook 'yaml-ts-mode-hook
            (lambda () (setq-local indent-line-function #'yaml-indent-line))))

;;; ===================================================================
;;; :lang javascript
;;; ===================================================================

(with-eval-after-load 'projectile
  (add-to-list 'projectile-project-root-files "package.json")
  (add-to-list 'projectile-globally-ignored-directories "node_modules")
  (add-to-list 'projectile-globally-ignored-directories "flow-typed"))

(defun +javascript-common-config (mode)
  (unless (eq mode 'nodejs-repl-mode)
    (when (modulep! +lsp)
      (add-hook (intern (format "%s-hook" mode)) #'lsp-deferred))))

(leaf js
  :ensure nil
  :mode ("\\.[mc]?js\\'" . js-mode)
  :mode ("\\.es6\\'" . js-mode)
  :mode ("\\.pac\\'" . js-mode)
  :config
  (+javascript-common-config 'js-mode)
  (when (modulep! +tree-sitter)
    (+javascript-common-config 'js-ts-mode))
  (setq js-chain-indent t))

(leaf typescript-mode
  :ensure t
  :unless (modulep! +tree-sitter)
  :mode "\\.ts\\'"
  :config
  (+javascript-common-config 'typescript-mode))

(leaf typescript-ts-mode ; 29.1+ only
  :ensure nil
  :when (modulep! +tree-sitter)
  :mode "\\.ts\\'"
  :mode ("\\.[tj]sx\\'" . tsx-ts-mode)
  :config
  (+javascript-common-config 'typescript-ts-mode)
  (+javascript-common-config 'tsx-ts-mode))

;; Parse node stack traces in the compilation buffer
(with-eval-after-load 'compilation
  (add-to-list 'compilation-error-regexp-alist 'node)
  (add-to-list 'compilation-error-regexp-alist-alist
               '(node "^[[:blank:]]*at \\(.*(\\|\\)\\(.+?\\):\\([[:digit:]]+\\):\\([[:digit:]]+\\)"
                 2 3 4)))

(leaf nodejs-repl
  :ensure t
  :config
  (+javascript-common-config 'nodejs-repl-mode))

;;; lang/markdown.el ends here