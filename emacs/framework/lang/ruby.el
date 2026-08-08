;;; lang/ruby.el --- doom lang/ruby port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/ruby.
;;; Code:

;;; lang/ruby
;; DEPRECATED: Remove when projectile is replaced with project.el
(after! projectile
  (add-to-list 'projectile-project-root-files "Gemfile"))

(leaf ruby-mode  ; built-in
  ;; Other extensions are already registered in `auto-mode-alist' by `ruby-mode'
  :ensure nil
  :mode ("\\.\\(?:a?rb\\|aslsx\\)\\'"
         "/\\(?:Brew\\|Fast\\)file\\'")
  :interpreter "j?ruby\\(?:[0-9.]+\\)"
  :config
  (setq ruby-insert-encoding-magic-comment nil)
  ;; so class and module pairs work
  (add-hook 'ruby-mode-hook (lambda () (setq-local sp-max-pair-length 6)))
  (with-eval-after-load 'inf-ruby
    ;; Switch to inf-ruby from compile if a breakpoint is detected
    (add-hook 'compilation-filter-hook #'inf-ruby-auto-enter))
  (when (modulep! +lsp)
    (add-hook 'ruby-mode-hook #'lsp)))
;; ruby-toggle-block (bound to the opening-bracket keys) is not defined
;; anywhere in the ported sources or vanilla ruby-mode; dropped.

;; ruby-ts-mode: gated on `+tree-sitter` (nil in compat); dropped.

(leaf yard-mode
  :ensure t
  :hook (ruby-mode . yard-mode))

(leaf ruby-json-to-hash
  :ensure t)

;;; Package & Ruby version management
(leaf inf-ruby
  :ensure t
  :commands inf-ruby)

(leaf rake
  :ensure t
  :init
  (with-eval-after-load 'rake
    (setq rake-cache-file (luna-profile-cache-dir t "rake.cache")
          rake-completion-system 'default)))

;; bundler: no nixpkgs emacs package; dropped.
;; chruby/rbenv/rvm: gated on +chruby/+rbenv (nil in compat); dropped.

;;; Testing frameworks
(leaf rspec-mode
  :ensure t
  :mode ("/\\.rspec\\'" . text-mode)
  :init
  (setq rspec-use-spring-when-possible nil)
  (when (modulep! :editor evil)
    (add-hook 'rspec-mode-hook #'evil-normalize-keymaps))
  :config
  (setq rspec-use-rvm (executable-find "rvm"))
)
(leaf minitest
  :ensure t
  :config
  (when (modulep! :editor evil)
    (add-hook 'minitest-mode-hook #'evil-normalize-keymaps))
)
;;; Rails integration
;; projectile-rails / rails-routes / rails-i18n / inflections: skipped per task
;; (+rails off).

;;; lang/ruby.el ends here