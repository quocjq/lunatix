;;; lang/nix.el --- doom lang/nix port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/nix.
;;; Code:

;;; -- nix helpers (autoload.el) ---------------------------------------------

(defun +nix--options-action (candidate)
  (switch-to-buffer-other-window
   (nixos-options-doc-buffer
    (nixos-options-get-documentation-for-option candidate))))

(defun +nix/open-repl ()
  "Open a nix repl."
  (interactive)
  (require 'nixos-options)
  (nix-repl-show)
  (current-buffer))

(defun +nix/lookup-option (&optional initial-input)
  "Look up documentation on a nix option."
  (interactive
   (list
    (when (and (looking-at-p "[a-zA-Z0-9-_\\.]")
               (not (luna-point-in-comment-p))
               (not (nth 3 (syntax-ppss))))
      (buffer-substring-no-properties
       (save-excursion
         (skip-chars-backward "^ ")
         (point))
       (save-excursion
         (skip-chars-forward "^ ")
         (point))))))
  (require 'nixos-options)
  (+nix--options-action
   (cdr (assoc (completing-read "NixOs options: "
                                nixos-options
                                nil
                                t
                                initial-input)
               nixos-options)))
  ;; Tell lookup module to let us handle things from here
  'deferred)

(defun +nix-shell-init-mode ()
  "Resolve a (cached-)?nix-shell shebang to the correct major mode."
  (save-excursion
    (goto-char (point-min))
    (save-match-data
      (if (not (and (re-search-forward "\\_<nix-shell " (line-end-position 2) t)
                    (re-search-forward "-i +\"?\\([^ \"\n]+\\)" (line-end-position) t)))
          (message "Couldn't determine mode for this script")
        (let* ((interp (match-string 1))
               (mode
                (assoc-default
                 interp
                 (mapcar (lambda (e)
                           (cons (format "\\`%s\\'" (car e))
                                 (cdr e)))
                         interpreter-mode-alist)
                 #'string-match-p)))
          (when mode
            (prog1 (set-auto-mode-0 mode)
              (when (eq major-mode 'sh-mode)
                (sh-set-shell interp)))))))))

;;; ===================================================================
;;; :lang sh
;;; ===================================================================

(defvar +sh-builtin-keywords
  '("cat" "cd" "chmod" "chown" "cp" "curl" "date" "echo" "find" "git" "grep"
    "kill" "less" "ln" "ls" "make" "mkdir" "mv" "pgrep" "pkill" "pwd" "rm"
    "sleep" "sudo" "touch")
  "A list of common shell commands to be fontified especially in `sh-mode'.")

(leaf sh-script ; built-in
  :ensure nil
  :mode ("\\.bats\\'" . sh-mode)
  :mode ("\\.\\(?:zunit\\|env\\)\\'" . sh-mode)
  :mode ("/bspwmrc\\'" . sh-mode)
  :magic ("#compdef " . sh-mode)
  :config
  (when (modulep! +lsp)
    (add-hook 'sh-mode-hook #'lsp-deferred))

  ;; nil LSP: auto-run `nix flake archive` when flake inputs are missing
  ;; (silences "Some flake inputs are not available..." without the
  ;; client-confirmation prompt)
  (when (modulep! +lsp)
    (after! lsp-mode
      (lsp-register-custom-settings '(("nil.nix.flake.autoArchive" t)))))

  (setq sh-indent-after-continuation 'always)

  (add-hook 'sh-mode-hook (lambda () (setq-local mode-name "Sh")))

  ;; recognize function names with dashes in them
  (add-to-list 'sh-imenu-generic-expression
               '(sh (nil "^\\s-*function\\s-+\\([[:alpha:]_-][[:alnum:]_-]*\\)\\s-*\\(?:()\\)?" 1)
                    (nil "^\\s-*\\([[:alpha:]_-][[:alnum:]_-]*\\)\\s-*()" 1)))

  ;; `sh-set-shell' is chatty about setting up indentation rules; quiet it.
  (defun +sh-shut-up-set-shell-a (fn &rest args)
    (let ((inhibit-message t))
      (apply fn args)))
  (advice-add #'sh-set-shell :around #'+sh-shut-up-set-shell-a)

  ;; 1. Fontifies variables in double quotes
  ;; 2. Fontify command substitution in double quotes
  ;; 3. Fontify built-in/common commands (see `+sh-builtin-keywords')
  (defun +sh-init-extra-fontification-h ()
    (font-lock-add-keywords
     nil `((+sh--match-variables-in-quotes
            (1 'font-lock-constant-face prepend)
            (2 'font-lock-variable-name-face prepend))
           (+sh--match-command-subst-in-quotes
            (1 'sh-quoted-exec prepend))
           (,(regexp-opt +sh-builtin-keywords 'symbols)
            (0 'font-lock-type-face append)))))
  (add-hook 'sh-mode-hook #'+sh-init-extra-fontification-h)

  ;; backtick pair (TAB-jumpable)
  (lnav-local-pair '(sh-mode) "`" "`"))
;;; ===================================================================
;;; :lang nix
;;; ===================================================================

(with-eval-after-load 'tramp
  (add-to-list 'tramp-remote-path "/run/current-system/sw/bin"))

(add-to-list 'auto-mode-alist
             (cons "/flake\\.lock\\'"
                   (if (modulep! :lang json)
                       'json-mode
                     'js-mode)))

(defun +nix-common-config (mode)
  (when (modulep! +lsp)
    (add-hook (intern (format "%s-hook" mode)) #'lsp-deferred))
  (let ((map (intern (format "%s-map" mode))))
    (general-define-key
     :keymaps map :states '(normal visual motion)
     :prefix luna-localleader-key
     "f" '(nix-update-fetch :wk "update fetch")
     "p" '(nix-format-buffer :wk "format buffer")
     "r" '(nix-repl-show :wk "repl")
     "s" '(nix-shell :wk "shell")
     "b" '(nix-build :wk "build")
     "u" '(nix-unpack :wk "unpack")
     "o" '(#'+nix/lookup-option :wk "lookup option"))))

(leaf nix-mode
  :ensure t
  :interpreter ("\\(?:cached-\\)?nix-shell" . +nix-shell-init-mode)
  :mode "\\.nix\\'"
  :config
  (+nix-common-config 'nix-mode))

(leaf nix-ts-mode
  :ensure t
  :when (modulep! +tree-sitter)
  :config
  (+nix-common-config 'nix-ts-mode))

(leaf nix-update
  :ensure t
  :commands nix-update-fetch)

(leaf nixos-options
  :ensure t
  :commands (nix-repl-show nixos-options))

;;; lang/cc.el ends here


;;; lang/nix.el ends here