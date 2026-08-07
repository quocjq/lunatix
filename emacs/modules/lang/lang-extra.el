;;; lang-extra.el --- lsp/web/python/markdown tweaks + builtin treesit remap  -*- lexical-binding: t; -*-

;;; Treesit — prefer builtin ts-modes for full highlighting (emacs 30).
;;; Only active when the grammar is installed; falls back to regex modes.
(require 'treesit)
(setq treesit-enabled-modes t
      ;; level 3 (default) looks "broken"; 4 = all font-lock features (doom)
      treesit-font-lock-level 4)
(setq major-mode-remap-alist
      '((c-mode . c-ts-mode)
        (c++-mode . c++-ts-mode)
        (python-mode . python-ts-mode)
        (js-mode . js-ts-mode)
        (typescript-mode . typescript-ts-mode)
        (go-mode . go-ts-mode)
        (rust-mode . rust-ts-mode)
        (nix-mode . nix-ts-mode)
        (sh-mode . bash-ts-mode)
        (yaml-mode . yaml-ts-mode)
        (json-mode . json-ts-mode)
        (css-mode . css-ts-mode)
        (html-mode . html-ts-mode)
        (java-mode . java-ts-mode)
        (ruby-mode . ruby-ts-mode)
        (php-mode . php-ts-mode)
        (lua-mode . lua-ts-mode)))

;;; LSP responsiveness
(after! lsp-mode
  (setq lsp-idle-delay 0.5
        lsp-enable-file-watchers nil
        lsp-enable-symbol-highlighting nil))
(after! lsp-ui
  (setq lsp-ui-doc-enable nil
        lsp-ui-sideline-enable nil))

;;; Web: 2-space indent
(after! web-mode
  (setq web-mode-markup-indent-offset 2
        web-mode-css-indent-offset 2
        web-mode-code-indent-offset 2))

;;; Python: no native-completion warning
(after! python
  (setq python-shell-completion-native-enable nil))

;;; Markdown heading faces
(custom-set-faces
 '(markdown-header-delimiter-face ((t (:foreground "#616161" :height 0.9))))
 '(markdown-header-face-1 ((t (:height 1.8 :foreground "#A3BE8C" :weight extra-bold :inherit markdown-header-face))))
 '(markdown-header-face-2 ((t (:height 1.4 :foreground "#EBCB8B" :weight extra-bold :inherit markdown-header-face))))
 '(markdown-header-face-3 ((t (:height 1.2 :foreground "#D08770" :weight extra-bold :inherit markdown-header-face))))
 '(markdown-header-face-4 ((t (:height 1.15 :foreground "#BF616A" :weight bold :inherit markdown-header-face))))
 '(markdown-header-face-5 ((t (:height 1.1 :foreground "#b48ead" :weight bold :inherit markdown-header-face))))
 '(markdown-header-face-6 ((t (:height 1.05 :foreground "#5e81ac" :weight semi-bold :inherit markdown-header-face))))

;;; lang-extra.el ends here
(provide 'lang-extra)
