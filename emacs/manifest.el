;;; manifest.el --- enabled modules, doom!-style. Single source of truth:
;;; feeds `modulep!' and documents what is active. Config side only.
;;;  -*- lexical-binding: t; -*-

(lunaris!
 :completion
 (corfu +orderless)
 (vertico +icons +childframe)

 :ui
 deft
 doom
 dashboard
 hl-todo
 indent-guides
 (ligatures +extra)
 modeline
 ophints
 (popup +defaults)
 smooth-scroll
 unicode
 (vc-gutter +pretty)
 window-select
 workspaces

 :editor
 (evil +everywhere)
 file-templates
 fold
 (format +onsave)
 parinfer
 rotate-text
 snippets
 (whitespace +guess +trim)

 :emacs
 (dired +dirvish)
 electric
 eww
 (ibuffer +icons)
 tramp
 undo
 vc

 :term
 eshell
 mistty

 :tools
 biblio
 (docker +tree-sitter)
 editorconfig
 (eval +overlay)
 lookup
 lsp
 (magit +forge)
 pass
 pdf
 tree-sitter
 upload

 :lang
 (agda +local)
 (cc +lsp)
 common-lisp
 data
 emacs-lisp
 (go +lsp)
 json
 (java +lsp)
 javascript
 (latex +lsp +fold +cdlatex)
 lean
 (lua +lsp)
 (markdown +lsp +tree-sitter +grip)
 (nix +lsp +tree-sitter)
 (org +pandoc)
 php
 (python +lsp +tree-sitter)
 (qt +lsp +tree-sitter)
 (ruby +rails)
 (rust +lsp)
 (sh +lsp)
 (web +lsp +tree-sitter)
 yaml

 :email
 (wanderlust +gmail)

 :app
 calendar
 irc
 (rss +org)

 :config
 literate
 (default +bindings +smartparens))

;;; manifest.el ends here
