;;; lang/sh.el --- doom lang/sh port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/sh.
;;; Code:

;;; -- sh helpers (autoload.el) ----------------------------------------------

(defun +sh--match-variables-in-quotes (limit)
  "Search for variables in double-quoted strings bounded by LIMIT."
  (with-syntax-table sh-mode-syntax-table
    (let (res)
      (while
          (and (setq res
                     (re-search-forward
                      "[^\\]\\(\\$\\)\\({.+?}\\|\\<[a-zA-Z0-9_]+\\|[@*#!]\\)"
                      limit t))
               (not (eq (nth 3 (syntax-ppss)) ?\"))))
      res)))

(defun +sh--match-command-subst-in-quotes (limit)
  "Search for variables in double-quoted strings bounded by LIMIT."
  (with-syntax-table sh-mode-syntax-table
    (let (res)
      (while
          (and (setq res
                     (re-search-forward "[^\\]\\(\\$(.+?)\\|`.+?`\\)"
                                        limit t))
               (not (eq (nth 3 (syntax-ppss)) ?\"))))
      res)))

(defun +sh/open-repl ()
  "Open a shell REPL."
  (interactive)
  (require 'sh-script)
  (let ((dest-sh (symbol-name sh-shell)))
    (dlet ((sh-shell-file dest-sh))
      (sh-shell-process t))
    (with-current-buffer "*shell*"
      (rename-buffer (format "*shell [%s]*" dest-sh))
      (current-buffer))))

(defun +sh-lookup-documentation-handler ()
  "Look up documentation in `man' or `woman'."
  (interactive)
  (require 'man)
  (let ((input (Man-default-man-entry)))
    (if (executable-find "man")
        (let* ((input (Man-translate-references input))
               (buffer (Man-getpage-in-background input)))
          (when (buffer-live-p buffer)
            (switch-to-buffer buffer)))
      (woman input t)
      (current-buffer))))

;;; ===================================================================
;;; :lang markdown
;;; ===================================================================

(defgroup +markdown nil
  "Enhances support for Markdown in Emacs."
  :group 'lisp)

(defcustom +markdown-compile-functions
  '(+markdown-compile-marked
    +markdown-compile-pandoc
    +markdown-compile-markdown
    +markdown-compile-multimarkdown)
  "A list of functions for `markdown-open' or `markdown-preview' to execute.

Stops at the first one to return non-nil. Each function takes three argument.
The beginning position of the region to capture, the end position, and the
output buffer."
  :type '(repeat function)
  :group '+markdown)

(defun +markdown-common-config (mode &rest extra-modes)
  (lnav-local-pair (cons mode extra-modes) "`" "`")

  (when (modulep! +lsp)
    (dolist (m (cons mode extra-modes))
      (add-hook (intern (format "%s-hook" m)) #'lsp-deferred)))


(leaf markdown-mode
  :ensure t
  :mode ("/README\\(?:\\.md\\)?\\'" . gfm-mode)
  :init
  (setq markdown-italic-underscore t
        markdown-gfm-additional-languages '("sh")
        markdown-make-gfm-checkboxes-buttons t
        markdown-fontify-whole-heading-line t
        markdown-fontify-code-blocks-natively t

        ;; `+markdown-compile' offers support for many transpilers (see
        ;; `+markdown-compile-functions'), which it tries until one succeeds.
        markdown-command #'+markdown-compile
        markdown-open-command
        (cond ((featurep :system 'macos) "open")
              ((featurep :system 'linux) "xdg-open"))

        ;; A sensible and simple default preamble for markdown exports that
        ;; takes after the github aesthetic (plus highlightjs syntax coloring).
        markdown-content-type "application/xhtml+xml"
        markdown-css-paths
        '("https://cdn.jsdelivr.net/npm/github-markdown-css/github-markdown.min.css"
          "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release/build/styles/github.min.css")
        markdown-xhtml-header-content
        (concat "<meta name='viewport' content='width=device-width, initial-scale=1, shrink-to-fit=no'>"
                "<style> body { box-sizing: border-box; max-width: 740px; width: 100%; margin: 40px auto; padding: 0 10px; } </style>"
                "<script id='MathJax-script' async src='https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js'></script>"
                "<script src='https://cdn.jsdelivr.net/gh/highlightjs/cdn-release/build/highlight.min.js'></script>"
                "<script>document.addEventListener('DOMContentLoaded', () => { document.body.classList.add('markdown-body'); document.querySelectorAll('pre[lang] > code').forEach((code) => { code.classList.add(code.parentElement.lang); }); document.querySelectorAll('pre > code').forEach((code) => { hljs.highlightBlock(code); }); });</script>")
        ;; Disabled to prevent accidentally clicking links while focusing Emacs
        ;; or a markdown buffer.
        markdown-mouse-follow-link nil)

  :config
  (+markdown-common-config 'markdown-mode 'gfm-mode)

  ;; Don't trigger autofill in code blocks (see `auto-fill-mode')
  (add-hook 'markdown-mode-hook
            (lambda ()
              (setq-local fill-nobreak-predicate
                          (cons #'markdown-code-block-at-point-p
                                fill-nobreak-predicate))))

  ;; HACK: Prevent mis-fontification of YAML metadata blocks in `markdown-mode'
  ;;   which occurs when the first line contains a colon in it.
  (defun +markdown-disable-front-matter-fontification-a (&rest _)
    (ignore (goto-char (point-max))))
  (advice-add #'markdown-match-generic-metadata :override #'+markdown-disable-front-matter-fontification-a)

  ;; HACK: markdown-mode calls a major mode without inhibiting its hooks, which
  ;;   could contain expensive functionality. Suppress it to speed up
  ;;   fontification.
  (defun +markdown-optimize-src-buffer-modes-a (fn &rest args)
    (delay-mode-hooks (apply fn args)))
  (advice-add #'markdown-fontify-code-block-natively :around #'+markdown-optimize-src-buffer-modes-a))

(leaf markdown-toc
  :ensure t
  :commands markdown-toc-generate-toc)

(leaf edit-indirect
  :ensure t
  :defer t)

(leaf evil-markdown
  :ensure t
  :when (modulep! :editor evil +everywhere)
  :hook (markdown-mode . evil-markdown-mode)
  :config
  (add-hook 'evil-markdown-mode-hook #'evil-normalize-keymaps)
))

;;; lang/sh.el ends here