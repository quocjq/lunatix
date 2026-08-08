;;; lang/javascript.el --- doom lang/javascript port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/javascript.
;;; Code:

;;; -- javascript helpers (autoload.el) ---------------------------------------

(defun +javascript-add-npm-path-h ()
  "Add node_modules/.bin to `exec-path'."
  (when-let* ((search-directory (or (luna-project-root) default-directory))
              (node-modules-parent (locate-dominating-file search-directory "node_modules/"))
              (node-modules-dir (expand-file-name "node_modules/.bin/" node-modules-parent)))
    (make-local-variable 'exec-path)
    (add-to-list 'exec-path node-modules-dir)
    (luna-log ":lang:javascript: add %s to $PATH" (expand-file-name "node_modules/" node-modules-parent))))

;; Approximation of doom's `def-project-mode! +javascript-npm-mode': add
;; node_modules/.bin to exec-path when in an npm project.
(defun +javascript--add-npm-path-maybe-h ()
  (when (and (derived-mode-p 'html-mode 'css-mode 'web-mode 'markdown-mode
                             'js-mode 'js-ts-mode 'json-mode 'json-ts-mode
                             'typescript-mode 'typescript-ts-mode 'tsx-ts-mode)
             (locate-dominating-file default-directory "package.json"))
    (+javascript-add-npm-path-h)))
(add-hook 'find-file-hook #'+javascript--add-npm-path-maybe-h)

(defun +javascript/open-repl ()
  "Open a Javascript REPL via `nodejs-repl'."
  (interactive)
  (nodejs-repl)
  (current-buffer))

;;; ===================================================================
;;; :lang web
;;; ===================================================================

(leaf emmet-mode
  :ensure t
  :preface (defvar emmet-mode-keymap (make-sparse-keymap))
  :hook ((css-mode web-mode html-mode nxml-mode) . emmet-mode)
  :config
  (when (require 'yasnippet nil t)
    (add-hook 'emmet-mode-hook #'yas-minor-mode-on))
  (setq emmet-move-cursor-between-quotes t))

(leaf web-mode
  :ensure t
  :mode "\\.[px]?html?\\'"
  :mode "\\.\\(?:tpl\\|blade\\)\\(?:\\.php\\)?\\'"
  :mode "\\.erb\\'"
  :mode "\\.[lh]?eex\\'"
  :mode "\\.jsp\\'"
  :mode "\\.as[cp]x\\'"
  :mode "\\.ejs\\'"
  :mode "\\.hbs\\'"
  :mode "\\.mustache\\'"
  :mode "\\.svelte\\'"
  :mode "\\.twig\\'"
  :mode "\\.jinja2?\\'"
  :mode "\\.eco\\'"
  :mode "wp-content/themes/.+/.+\\.php\\'"
  :mode "templates/.+\\.php\\'"
  :init
  ;; If the user has installed `vue-mode' then, by appending this to
  ;; `auto-mode-alist' rather than prepending it, its autoload will have
  ;; priority over this one.
  (add-to-list 'auto-mode-alist '("\\.vue\\'" . web-mode) 'append)
  :config
  (setq web-mode-enable-html-entities-fontification t
        web-mode-auto-close-style 1)

  (lnav-local-pair '(web-mode) "<" ">")

  ;; web-mode auto-pair cleanup (was under smartparens; now standalone)
  (setq web-mode-enable-auto-quoting nil
        web-mode-enable-auto-pairing t)

  ;; 1. Remove web-mode auto pairs whose end pair starts with a letter
  ;;    (truncated autopairs like <?p and hp ?>).
  ;; 2. Strips out extra closing pairs to prevent redundant characters.
  (dolist (alist web-mode-engines-auto-pairs)
    (setcdr alist
            (cl-loop for pair in (cdr alist)
                     unless (string-match-p "^[a-z-]" (cdr pair))
                     collect (cons (car pair)
                                   (string-trim-right (cdr pair)
                                                      "\\(?:>\\|]\\|}\\)+\\'")))))
  (cl-callf2 delq nil web-mode-engines-auto-pairs)

  (add-to-list 'web-mode-engines-alist '("elixir" . "\\.eex\\'"))
  (add-to-list 'web-mode-engines-alist '("phoenix" . "\\.[lh]eex\\'"))

  ;; Use // instead of /* as the default comment delimited in JS
  (setf (alist-get "javascript" web-mode-comment-formats nil nil #'equal)
        "//")

  (defun +web--fix-js-comments-h ()
    "Fix comment handling in `web-mode' for JavaScript."
    (when (member web-mode-content-type '("javascript" "jsx"))
      (setq-local comment-start "//")
      (setq-local comment-end "")
      (setq-local comment-start-skip "// *")))
  (add-hook 'web-mode-hook #'+web--fix-js-comments-h))

(when (modulep! +lsp)
  (add-hook 'html-mode-hook #'lsp-deferred)
  (add-hook 'html-ts-mode-hook #'lsp-deferred)
  (add-hook 'web-mode-hook #'lsp-deferred)
  (add-hook 'nxml-mode-hook #'lsp-deferred))

;;; lang/javascript.el ends here