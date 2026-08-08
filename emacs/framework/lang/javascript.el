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
  (setq emmet-move-cursor-between-quotes t)
  (general-define-key
   :keymaps 'emmet-mode-keymap
   :states '(visual)
   [tab] #'emmet-wrap-with-markup)
  (general-define-key
   :keymaps 'emmet-mode-keymap
   [tab] #'+web/indent-or-yas-or-emmet-expand
   "M-E" #'emmet-expand-line))

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
  (add-hook 'web-mode-hook #'+web--fix-js-comments-h)

  (general-define-key
   :keymaps 'web-mode-map
   :states '(normal visual motion)
   :prefix luna-localleader-key
   "h" '(web-mode-reload :wk "rehighlight buffer")
   "i" '(web-mode-buffer-indent :wk "indent buffer")
   "ab" '(web-mode-attribute-beginning :wk "attribute beginning")
   "ae" '(web-mode-attribute-end :wk "attribute end")
   "ai" '(web-mode-attribute-insert :wk "attribute insert")
   "an" '(web-mode-attribute-next :wk "attribute next")
   "as" '(web-mode-attribute-select :wk "attribute select")
   "ak" '(web-mode-attribute-kill :wk "attribute kill")
   "ap" '(web-mode-attribute-previous :wk "attribute previous")
   "at" '(web-mode-attribute-transpose :wk "attribute transpose")
   "bb" '(web-mode-block-beginning :wk "block beginning")
   "bc" '(web-mode-block-close :wk "block close")
   "be" '(web-mode-block-end :wk "block end")
   "bk" '(web-mode-block-kill :wk "block kill")
   "bn" '(web-mode-block-next :wk "block next")
   "bp" '(web-mode-block-previous :wk "block previous")
   "bs" '(web-mode-block-select :wk "block select")
   "da" '(web-mode-dom-apostrophes-replace :wk "dom apostrophes replace")
   "dd" '(web-mode-dom-errors-show :wk "dom errors show")
   "de" '(web-mode-dom-entities-encode :wk "dom entities encode")
   "dn" '(web-mode-dom-normalize :wk "dom normalize")
   "dq" '(web-mode-dom-quotes-replace :wk "dom quotes replace")
   "dt" '(web-mode-dom-traverse :wk "dom traverse")
   "dx" '(web-mode-dom-xpath :wk "dom xpath")
   "e/" '(web-mode-element-close :wk "element close")
   "ea" '(web-mode-element-content-select :wk "element content select")
   "eb" '(web-mode-element-beginning :wk "element beginning")
   "ec" '(web-mode-element-clone :wk "element clone")
   "ed" '(web-mode-element-child :wk "element child")
   "ee" '(web-mode-element-end :wk "element end")
   "ef" '(web-mode-element-children-fold-or-unfold :wk "element fold/unfold")
   "ei" '(web-mode-element-insert :wk "element insert")
   "ek" '(web-mode-element-kill :wk "element kill")
   "em" '(web-mode-element-mute-blanks :wk "element mute blanks")
   "en" '(web-mode-element-next :wk "element next")
   "ep" '(web-mode-element-previous :wk "element previous")
   "er" '(web-mode-element-rename :wk "element rename")
   "es" '(web-mode-element-select :wk "element select")
   "et" '(web-mode-element-transpose :wk "element transpose")
   "eu" '(web-mode-element-parent :wk "element parent")
   "ev" '(web-mode-element-vanish :wk "element vanish")
   "ew" '(web-mode-element-wrap :wk "element wrap")
   "ta" '(web-mode-tag-attributes-sort :wk "tag attributes sort")
   "tb" '(web-mode-tag-beginning :wk "tag beginning")
   "te" '(web-mode-tag-end :wk "tag end")
   "tm" '(web-mode-tag-match :wk "tag match")
   "tn" '(web-mode-tag-next :wk "tag next")
   "tp" '(web-mode-tag-previous :wk "tag previous")
   "ts" '(web-mode-tag-select :wk "tag select"))

  (general-define-key
   :keymaps 'web-mode-map
   :states '(insert)
   "SPC" #'self-insert-command)
  (general-define-key
   :keymaps 'web-mode-map
   :states '(normal)
   "za" #'web-mode-fold-or-unfold)
  (general-define-key
   :keymaps 'web-mode-map
   :states '(normal visual)
   "]a" #'web-mode-attribute-next
   "[a" #'web-mode-attribute-previous
   "]t" #'web-mode-tag-next
   "[t" #'web-mode-tag-previous
   "]T" #'web-mode-element-child
   "[T" #'web-mode-element-parent))

(when (modulep! +lsp)
  (add-hook 'html-mode-hook #'lsp-deferred)
  (add-hook 'html-ts-mode-hook #'lsp-deferred)
  (add-hook 'web-mode-hook #'lsp-deferred)
  (add-hook 'nxml-mode-hook #'lsp-deferred))

;;; lang/javascript.el ends here