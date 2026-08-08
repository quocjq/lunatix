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
  :ensure t
  :init
  (with-eval-after-load 'ruby-mode
    (general-def :keymaps 'ruby-mode-map :prefix luna-localleader-key
      "J" #'ruby-json-to-hash-parse-json
      "j" #'ruby-json-to-hash-toggle-let)))

;;; Package & Ruby version management
(leaf inf-ruby
  :ensure t
  :commands inf-ruby)

(leaf rake
  :ensure t
  :init
  (with-eval-after-load 'rake
    (setq rake-cache-file (luna-profile-cache-dir t "rake.cache")
          rake-completion-system 'default))
  (with-eval-after-load 'ruby-mode
    (general-def :keymaps 'ruby-mode-map
      :prefix (concat luna-localleader-key " k")
      "k" #'rake
      "r" #'rake-rerun
      "R" #'rake-regenerate-cache
      "f" #'rake-find-task)))

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
  (general-def :keymaps '(rspec-verifiable-mode-map rspec-dired-mode-map rspec-mode-map)
    :prefix (concat luna-localleader-key " t")
    "a" #'rspec-verify-all
    "r" #'rspec-rerun)
  (general-def :keymaps '(rspec-verifiable-mode-map rspec-mode-map)
    :prefix (concat luna-localleader-key " t")
    "v" #'rspec-verify
    "c" #'rspec-verify-continue
    "l" #'rspec-run-last-failed
    "T" #'rspec-toggle-spec-and-target
    "t" #'rspec-toggle-spec-and-target-find-example)
  (general-def :keymaps 'rspec-verifiable-mode-map
    :prefix (concat luna-localleader-key " t")
    "f" #'rspec-verify-method
    "m" #'rspec-verify-matching)
  (general-def :keymaps 'rspec-mode-map
    :prefix (concat luna-localleader-key " t")
    "s" #'rspec-verify-single
    "e" #'rspec-toggle-example-pendingness)
  (general-def :keymaps 'rspec-dired-mode-map
    :prefix (concat luna-localleader-key " t")
    "v" #'rspec-dired-verify
    "s" #'rspec-dired-verify-single))

(leaf minitest
  :ensure t
  :config
  (when (modulep! :editor evil)
    (add-hook 'minitest-mode-hook #'evil-normalize-keymaps))
  (general-def :keymaps 'minitest-mode-map
    :prefix (concat luna-localleader-key " t")
    "r" #'minitest-rerun
    "a" #'minitest-verify-all
    "s" #'minitest-verify-single
    "v" #'minitest-verify))

;;; Rails integration
;; projectile-rails / rails-routes / rails-i18n / inflections: skipped per task
;; (+rails off).

;;; lang/ruby.el ends here