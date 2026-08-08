;;; lang/web.el --- doom lang/web port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/web.
;;; Code:

;;; -- web +css ---------------------------------------------------------------

(defvar +web-continue-block-comments t
  "If non-nil, newlines in block comments are continued with a leading *.

This also indirectly means the asterisks in the opening /* and closing */ will
be aligned.

If set to `nil', disable all the above behaviors.")

(add-to-list 'find-sibling-rules '("/\\([^/]+\\)\\.\\(\\(s[ac]\\|le\\)ss\\|styl\\)\\'" "\\1\\.css\\'"))
(add-to-list 'find-sibling-rules '("/\\([^/]+\\)\\.css\\'" "\\1\\.\\(\\(s[ac]\\|le\\)ss\\|styl\\)\\'"))

;; Correctly continue /* and // comments on newline-and-indent
(add-hook 'css-mode-hook
          (lambda ()
            (setq-local comment-line-break-function #'+css/comment-indent-new-line)
            (setq-local adaptive-fill-function #'+css-adaptive-fill-fn)
            (setq-local adaptive-fill-first-line-regexp "\\'[ \t]*\\(?:\\* *\\)?\\'")))

(add-hook 'css-mode-hook #'rainbow-mode)
(add-hook 'sass-mode-hook #'rainbow-mode)
(add-hook 'stylus-mode-hook #'rainbow-mode)

(with-eval-after-load 'css-mode
  (general-define-key
   :keymaps '(css-mode-map scss-mode-map less-css-mode-map)
   :states '(normal visual motion)
   :prefix luna-localleader-key
   "rb" '(#'+css/toggle-inline-or-block :wk "toggle inline/block")))

(when (modulep! +lsp)
  (add-hook 'css-mode-hook #'lsp-deferred)
  (add-hook 'css-ts-mode-hook #'lsp-deferred)
  (add-hook 'scss-mode-hook #'lsp-deferred)
  (add-hook 'sass-mode-hook #'lsp-deferred)
  (add-hook 'less-css-mode-hook #'lsp-deferred))

(leaf rainbow-mode
  :ensure t
  :defer t)

(leaf sass-mode
  :ensure t
  :defer t)

;;; -- web helpers (autoload/html.el, autoload/css.el) -------------------------

(defun +web/indent-or-yas-or-emmet-expand ()
  "Do-what-I-mean on TAB.

Invokes `indent-for-tab-command' if at or before text bol, `yas-expand' if on a
snippet, or `emmet-expand-yas'/`emmet-expand-line', depending on whether
`yas-minor-mode' is enabled or not."
  (interactive)
  (call-interactively
   (cond ((or (<= (current-column) (current-indentation))
              (not (eolp))
              (not (or (memq (char-after) (list ?\n ?\s ?\t))
                       (eobp))))
          #'indent-for-tab-command)
         ((modulep! :editor snippets)
          (require 'yasnippet)
          (if (yas--templates-for-key-at-point)
              #'yas-expand
            #'emmet-expand-yas))
         (#'emmet-expand-line))))

(defun +css--toggle-inline-or-block (beg end)
  (skip-chars-forward " \t")
  (let ((orig (point-marker)))
    (goto-char beg)
    (if (= (line-number-at-pos beg) (line-number-at-pos end))
        (progn
          (forward-char)
          (insert "\n")
          (while (re-search-forward ";\\s-+" end t)
            (replace-match ";\n" nil t))
          (indent-region beg end))
      (save-excursion
        (while (re-search-forward "\n+" end t)
          (replace-match " " nil t)))
      (while (re-search-forward "\\([{;]\\) +" end t)
        (replace-match (concat (match-string 1) " ") nil t)))
    (if orig (goto-char orig))
    (skip-chars-forward " \t")))

(defun +css/toggle-inline-or-block ()
  "Toggles between a bracketed block and inline block."
  (interactive)
  (let ((inhibit-modification-hooks t))
    (cl-destructuring-bind (&key beg end op cl &allow-other-keys)
        (save-excursion
          (when (and (eq (char-after) ?\{)
                     (not (eq (char-before) ?\{)))
            (forward-char))
          (sp-get-sexp))
      (when (or (not (and beg end op cl))
                (string-empty-p op) (string-empty-p cl))
        (user-error "No block found %s" (list beg end op cl)))
      (unless (string= op "{")
        (user-error "Incorrect block found"))
      (+css--toggle-inline-or-block beg end))))

(defun +css/comment-indent-new-line (&optional _)
  "Continues the comment in an indented new line.

Meant for `comment-line-break-function' in `css-mode' and `scss-mode'."
  (interactive)
  (cond ((or (not (luna-point-in-comment-p))
             (and comment-use-syntax
                  (not (save-excursion (comment-beginning)))))
         (let (comment-line-break-function)
           (newline-and-indent)))

        ((save-match-data
           (let ((at-end (looking-at-p ".+\\*/"))
                 (indent-char (if indent-tabs-mode ?\t ?\s))
                 (post-indent (save-excursion
                                (move-to-column (1+ (current-indentation)))
                                (skip-chars-forward " \t" (line-end-position))))
                 (pre-indent (current-indentation))
                 opener)
             (save-excursion
               (if comment-use-syntax
                   (goto-char (comment-beginning))
                 (goto-char (line-beginning-position))
                 (when (re-search-forward comment-start-skip (line-end-position) t)
                   (goto-char (or (match-end 1)
                                  (match-beginning 0)))))
               (if (looking-at "\\(//\\|/?\\*\\**/?\\)\\(?:[^/]\\)")
                   (setq opener (match-string-no-properties 1)
                         pre-indent (- (match-beginning 1) (line-beginning-position)))
                 (setq opener ""
                       pre-indent 0)))
             (insert-and-inherit
              "\n" (make-string pre-indent indent-char)
              (if (string-prefix-p "/*" opener)
                  (if (or (eq +web-continue-block-comments t)
                          (string= "/**" opener))
                      " *"
                    "")
                opener)
              (make-string post-indent indent-char))
             (when at-end
               (save-excursion
                 (just-one-space)
                 (insert "\n" (make-string pre-indent indent-char)))))))))

(defun +css-adaptive-fill-fn ()
  "An `adaptive-fill-function' that conjoins SCSS line comments correctly."
  (when (looking-at "[ \t]*/[/*][ \t]*")
    (let ((str (match-string 0)))
      (when (string-match "/[/*]" str)
        (replace-match (if (string= (match-string 0 str) "/*")
                           " *"
                         "//")
                       t t str)))))

;;; ===================================================================
;;; Packages dropped during the port (no nixpkgs package / dead flag):
;;;   - nose (python test runner; not in nixpkgs)
;;;   - pyenv-mode, uv-mode, conda, poetry, lsp-pyright (+pyenv/+uv/+conda/
;;;     +poetry/+pyright flags disabled)
;;;   - cython-mode, flycheck-cython (+cython disabled)
;;;   - flycheck-package, package-lint-flymake (:checkers syntax uses neither
;;;     the -flymake nor +flymake flag in this config)
;;;   - company-shell, bash-completion (:completion company disabled / +lsp
;;;     enabled)
;;;   - counsel-jq, helm-nixos-options, counsel-css, helm-css-scss (ivy/helm
;;;     completion disabled)
;;;   - ccls (+lsp but :tools lsp -eglot false)
;;;   - markdown-ts-mode, html-ts-mode, mhtml-ts-mode, css-ts-mode,
;;;     yaml-ts-mode, json-ts-mode, go-work/ts treesitter remaps
;;;     (set-tree-sitter! has no port; builtin ts modes not wired)
;;;   - ox-rst (:lang rst not ported), org-contrib, ob-go, org-roam,
;;;     org-download, org-journal, org-noter, org-modern, org-appear,
;;;     org-tree-slide, centered-window (org +flags disabled)
;;;   - evil-org's cl-defmethod for rust-analyzer signatures (requires dash/s,
;;;     only under -eglot)
;;;   - the org popup rules (set-popup-rules! has no port)

;;; lang/web.el ends here