;;; lang/go.el --- doom lang/go port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/go.
;;; Code:

;;; -- go helpers (autoload.el) ----------------------------------------------

(defun +go--spawn (cmd)
  (save-selected-window
    (compile cmd)))

(defun +go--assert-buffer-visiting ()
  (unless buffer-file-name
    (user-error "Not in a file-visiting buffer")))

(defvar +go-test-last nil
  "The last test run.")

(defun +go--run-tests (args)
  (let ((cmd (concat "go test -test.v " args)))
    (setq +go-test-last (concat "cd " default-directory ";" cmd))
    (+go--spawn cmd)))

(defun +go/test-rerun ()
  "Rerun last run test."
  (interactive)
  (if +go-test-last
      (+go--spawn +go-test-last)
    (+go/test-all)))

(defun +go/test-all ()
  "Run all tests for this project."
  (interactive)
  (+go--run-tests ""))

(defun +go/test-nested ()
  "Run all tests in current directory and below, recursively."
  (interactive)
  (+go--run-tests "./..."))

(defun +go/test-single ()
  "Run single test at point."
  (interactive)
  (+go--assert-buffer-visiting)
  (unless (string-match-p "_test\\.go$" buffer-file-name)
    (user-error "Must be in a *_test.go file"))
  (save-excursion
    (save-match-data
      (unless (re-search-backward "^func[ ]+\\(([[:alnum:]]*?[ ]?[*]?[[:alnum:]]+)[ ]+\\)?\\(Test[[:alnum:]_]+\\)(.*)" nil t)
        (user-error "No detectable test at or after point"))
      (+go--run-tests (concat "-run" "='^\\Q" (match-string-no-properties 2) "\\E$'")))))

(defun +go/test-file ()
  "Run all tests in current file."
  (interactive)
  (+go--assert-buffer-visiting)
  (unless (string-match-p "_test\\.go$" buffer-file-name)
    (user-error "Must be in a *_test.go file"))
  (save-excursion
    (save-match-data
      (goto-char (point-min))
      (let (func-list)
        (while (re-search-forward "^func[ ]+\\(([[:alnum:]]*?[ ]?[*]?[[:alnum:]]+)[ ]+\\)?\\(Test[[:alnum:]_]+\\)(.*)" nil t)
          (push (match-string-no-properties 2) func-list))
        (unless func-list
          (user-error "No detectable tests in this file"))
        (+go--run-tests (concat "-run" "='^(" (string-join func-list "|")  ")$'"))))))

(defun +go/bench-all ()
  "Run all benchmarks in project."
  (interactive)
  (+go--run-tests "-test.run=NONE -test.bench=\".*\""))

(defun +go/bench-single ()
  "Run benchmark at point."
  (interactive)
  (if (string-match "_test\\.go" buffer-file-name)
      (save-excursion
        (re-search-backward "^func[ ]+\\(([[:alnum:]]*?[ ]?[*]?[[:alnum:]]+)[ ]+\\)?\\(Benchmark[[:alnum:]_]+\\)(.*)")
        (+go--run-tests (concat "-test.run=NONE -test.bench" "='^\\Q" (match-string-no-properties 2) "\\E$'")))
    (error "Must be in a _test.go file")))

(defun +go--generate (dir args)
  (unless (file-directory-p dir)
    (user-error "Directory does not exist: %s" dir))
  (+go--spawn
   (format "cd %s && go generate %s"
           (shell-quote-argument dir)
           args)))

(defun +go/generate-file ()
  "Run 'go generate' for the current file."
  (interactive)
  (+go--assert-buffer-visiting)
  (+go--generate default-directory
                 (file-name-nondirectory buffer-file-name)))

(defun +go/generate-dir ()
  "Run 'go generate' for the current directory, recursively."
  (interactive)
  (+go--generate default-directory "./..."))

(defun +go/generate-all (&optional arg)
  "Run 'go generate' for the entire project.
Will prompt for the project if you're not in one or if the prefix ARG is
non-nil."
  (interactive "P")
  (let ((proot (or (luna-project-root)
                   (if arg (read-directory-name "Project root: ") nil))))
    (if proot
        (+go--generate (file-truename proot) "./...")
      (user-error "Not in a valid project"))))

(defun +go/play-buffer-or-region (&optional beg end)
  "Evaluate active selection or buffer in the Go playground."
  (interactive "r")
  (if (use-region-p)
      (go-play-region beg end)
    (go-play-buffer)))

;;; ===================================================================
;;; :lang cc
;;; ===================================================================

(defvar +cc-default-include-paths
  (list "include"
        "includes")
  "A list of default relative paths which will be searched for up from the
current file. Paths can be absolute. This is ignored if your project has a
compilation database.")

(defvar +cc-default-header-file-mode 'c-mode
  "Fallback major mode for .h files if all other heuristics fail (in
`+cc-c-c++-objc-mode').")

(leaf cc-mode
  :ensure nil
  :mode ("\\.mm\\'" . objc-mode)
  ;; Use `c-mode'/`c++-mode'/`objc-mode' depending on heuristics
  :mode ("\\.h\\'" . +cc-c-c++-objc-mode)
  ;; Ensure find-file-at-point recognizes system libraries in C modes.
  :hook ((c-mode-hook c++-mode-hook objc-mode-hook) . +cc-init-ffap-integration-h)
  :init
  (after! ffap
    (add-to-list 'ffap-alist '(c-mode . ffap-c-mode))
    (add-to-list 'ffap-alist '(c-ts-mode . ffap-c-mode))
    (add-to-list 'ffap-alist '(c++-ts-mode . ffap-c++-mode)))
  :config
  ;; HACK: cc-mode adds null entries to `major-mode-remap-defaults'; leave
  ;;   tree-sitter remapping to the user. (set-tree-sitter! has no port here.)
  (add-to-list 'find-sibling-rules '("/\\([^/]+\\)\\.c\\(c\\|pp\\)?\\'" "\\1.h\\(h\\|pp\\)?\\'"))
  (add-to-list 'find-sibling-rules '("/\\([^/]+\\)\\.h\\(h\\|pp\\)?\\'" "\\1.c\\(c\\|pp\\)?\\'"))

  ;; HACK: Suppress 'Args out of range' error when multiple modifications are
  ;;   performed at once in a `c++-mode' buffer, e.g. with `iedit'.
  (defun +cc--suppress-silly-errors-a (fn &rest args)
    (ignore-errors (apply fn args)))
  (advice-add #'c-after-change-mark-abnormal-strings :around #'+cc--suppress-silly-errors-a)

  ;; Custom style, based off of linux
  (setq c-basic-offset tab-width
        c-backspace-function #'delete-backward-char)

  (c-add-style
   "doom" '((c-comment-only-line-offset . 0)
            (c-hanging-braces-alist (brace-list-open)
                                    (brace-entry-open)
                                    (substatement-open after)
                                    (block-close . c-snug-do-while)
                                    (arglist-cont-nonempty))
            (c-cleanup-list brace-else-brace)
            (c-offsets-alist
             (knr-argdecl-intro . 0)
             (substatement-open . 0)
             (substatement-label . 0)
             (statement-cont . +)
             (case-label . +)
             ;; align args with open brace OR don't indent at all
             (brace-list-intro . 0)
             (brace-list-close . -)
             (arglist-intro . +)
             (arglist-close +cc-lineup-arglist-close 0)
             ;; don't over-indent lambda blocks
             (inline-open . 0)
             (inlambda . 0)
             ;; indent access keywords +1 level, and properties beneath them
             ;; another level
             (access-label . -)
             (inclass +cc-c++-lineup-inclass +)
             (label . 0))))

  (when (listp c-default-style)
    (setf (alist-get 'other c-default-style) "doom")))

(leaf cmake-mode
  :ensure t
  :config
  (when (modulep! +lsp)
    (add-hook 'cmake-mode-hook #'lsp-deferred)))

(leaf glsl-mode
  :ensure t
  :config
  (when (modulep! +lsp)
    (add-hook 'glsl-mode-hook #'lsp-deferred)))

(leaf cuda-mode
  :ensure t
  :config
  (when (modulep! +lsp)
    (add-hook 'cuda-mode-hook #'lsp-deferred)))

(leaf demangle-mode
  :ensure t
  :hook llvm-mode)

(when (modulep! +lsp)
  (add-hook 'c-mode-hook #'lsp-deferred)
  (add-hook 'c-ts-mode-hook #'lsp-deferred)
  (add-hook 'c++-mode-hook #'lsp-deferred)
  (add-hook 'c++-ts-mode-hook #'lsp-deferred)
  (add-hook 'objc-mode-hook #'lsp-deferred)

  (after! lsp-clangd
    ;; Prevent clangd from consuming all your cores indexing larger projects
    ;; and grinding your system to a halt.
    (cl-pushnew (format "-j=%d" (max 1 (/ (luna-system-cpus) 2)))
                lsp-clients-clangd-args)))

;;; lang/go.el ends here