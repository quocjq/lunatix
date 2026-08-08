;;; lang/python.el --- doom lang/python port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/python.
;;; Code:

(leaf python
  :ensure nil
  :mode ("/\\(?:Pipfile\\|\\.?flake8\\)\\'" . conf-mode)
  :init
  (setq python-environment-directory (luna-profile-cache-dir)
        python-indent-guess-indent-offset-verbose nil)
  :config
  ;; HACK: `python-base-mode' (and `python-ts-mode') don't exist on pre-29
  ;;   versions of Emacs, so shim the keymap in.
  (unless (boundp 'python-base-mode-map)
    (defvaralias 'python-base-mode-map 'python-mode-map))

  (when (modulep! +lsp)
    (add-hook 'python-mode-hook #'lsp-deferred)
    (add-hook 'python-ts-mode-hook #'lsp-deferred))

  ;; Stop the spam!
  (setq python-indent-guess-indent-offset-verbose nil)

  ;; Default to Python 3. Prefer the versioned Python binaries since some
  ;; systems link the unversioned one to Python 2.
  (when (and (string= python-shell-interpreter "python") ; only if unmodified
             (executable-find "python3"))
    (setq python-shell-interpreter "python3"))

  ;; HACK: Python 3.13's pyrepl mishandles SIGINT under Emacs's comint
  ;;   (TERM=dumb). Disabling pyrepl forces the classic readline-based REPL.
  (add-to-list 'python-shell-process-environment "PYTHON_BASIC_REPL=1")

  (defun +python-use-correct-flycheck-executables-h ()
    "Use the correct Python executables for Flycheck."
    (let ((executable python-shell-interpreter))
      (save-excursion
        (goto-char (point-min))
        (save-match-data
          (when (or (looking-at "#!/usr/bin/env \\(python[^ \n]+\\)")
                    (looking-at "#!\\([^ \n]+/python[^ \n]+\\)"))
            (setq executable (substring-no-properties (match-string 1))))))
      ;; Try to compile using the appropriate version of Python for the file.
      (setq-local flycheck-python-pycompile-executable executable)
      ;; We might be running inside a virtualenv, in which case the modules
      ;; won't be available. But calling the executables directly will work.
      (setq-local flycheck-python-pylint-executable "pylint")
      (setq-local flycheck-python-flake8-executable "flake8")))
  (add-hook 'python-mode-hook #'+python-use-correct-flycheck-executables-h)
  (add-hook 'python-ts-mode-hook #'+python-use-correct-flycheck-executables-h))

(leaf python-pytest
  :ensure t
  :commands python-pytest-dispatch
  :config
  (general-define-key
   :keymaps 'python-base-mode-map
   :states '(normal visual motion)
   :prefix luna-localleader-key
   "ta" '(python-pytest :wk "pytest")
   "tf" '(python-pytest-file-dwim :wk "pytest file dwim")
   "tF" '(python-pytest-file :wk "pytest file")
   "tt" '(python-pytest-run-def-or-class-at-point-dwim :wk "run def/class dwim")
   "tT" '(python-pytest-run-def-or-class-at-point :wk "run def/class")
   "tr" '(python-pytest-repeat :wk "pytest repeat")
   "tp" '(python-pytest-dispatch :wk "pytest dispatch")))

(leaf pip-requirements
  :ensure t
  :config
  ;; HACK: `pip-requirements-mode' performs a sudden HTTP request to
  ;;   https://pypi.org/simple on mode load; defer it until the first time
  ;;   completion is invoked.
  (defun +python--init-completion-a (&rest _)
    "Call `pip-requirements-fetch-packages' first time completion is invoked."
    (unless pip-packages (pip-requirements-fetch-packages)))
  (advice-add #'pip-requirements-complete-at-point :before #'+python--init-completion-a)

  (defun +python--inhibit-pip-requirements-fetch-packages-a (fn &rest args)
    "No-op `pip-requirements-fetch-packages', which can be expensive."
    (cl-letf (((symbol-function 'pip-requirements-fetch-packages) #'ignore))
      (apply fn args)))
  (advice-add #'pip-requirements-mode :around #'+python--inhibit-pip-requirements-fetch-packages-a))

(leaf pyvenv
  :ensure t
  :after python
  :config
  (add-hook 'python-mode-hook #'pyvenv-track-virtualenv)
  (add-hook 'python-ts-mode-hook #'pyvenv-track-virtualenv)
  (add-to-list 'global-mode-string
               '(pyvenv-virtual-env-name (" venv:" pyvenv-virtual-env-name " "))
               'append))

(leaf pipenv
  :ensure t
  :commands pipenv-project-p
  :hook (python-mode . pipenv-mode)
  :init (setq pipenv-with-projectile nil)
  :config
  (general-define-key
   :keymaps 'python-base-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " e")
   "a" '(pipenv-activate :wk "activate")
   "d" '(pipenv-deactivate :wk "deactivate")
   "i" '(pipenv-install :wk "install")
   "l" '(pipenv-lock :wk "lock")
   "o" '(pipenv-open :wk "open module")
   "r" '(pipenv-run :wk "run")
   "s" '(pipenv-shell :wk "shell")
   "u" '(pipenv-uninstall :wk "uninstall")))

;;; -- python helpers (autoload/python.el) -----------------------------------

(defun +python-executable-find (exe)
  "Resolve the path to the EXE executable.
Tries to be aware of your active conda/pipenv/virtualenv environment, before
falling back on searching your PATH."
  (if (file-name-absolute-p exe)
      (and (file-executable-p exe)
           exe)
    (let ((exe-root (format "bin/%s" exe)))
      (cond ((when python-shell-virtualenv-root
               (let ((bin (expand-file-name exe-root python-shell-virtualenv-root)))
                 (if (file-exists-p bin) bin))))
            ((when (require 'conda nil t)
               (let ((bin (expand-file-name (concat conda-env-current-name "/" exe-root)
                                            (conda-env-default-location))))
                 (if (file-executable-p bin) bin))))
            ((when-let* ((bin (locate-dominating-file
                               default-directory
                               (lambda (dir) (file-exists-p (expand-file-name exe-root dir))))))
               (expand-file-name exe-root bin)))
            ((executable-find exe))))))

(defun +python/open-repl ()
  "Open the Python REPL."
  (interactive)
  (require 'python)
  (unless python-shell-interpreter
    (user-error "`python-shell-interpreter' isn't set"))
  (pop-to-buffer
   (process-buffer
    (let ((dedicated (bound-and-true-p python-shell-dedicated)))
      (if-let* ((pipenv (+python-executable-find "pipenv"))
                (pipenv-project (pipenv-project-p)))
          (let ((default-directory pipenv-project)
                (python-shell-interpreter-args
                 (format "run %s %s"
                         python-shell-interpreter
                         python-shell-interpreter-args))
                (python-shell-interpreter pipenv))
            (run-python nil dedicated t))
        (run-python nil dedicated t))))))

(defun +python/open-ipython-repl ()
  "Open an IPython REPL."
  (interactive)
  (require 'python)
  (let ((python-shell-interpreter
         (or (+python-executable-find (car +python-ipython-command))
             "ipython"))
        (python-shell-interpreter-args
         (string-join (cdr +python-ipython-command) " ")))
    (+python/open-repl)))

;;; ===================================================================
;;; :lang rust
;;; ===================================================================

(with-eval-after-load 'projectile
  (add-to-list 'projectile-project-root-files "Cargo.toml"))

;; HACK: Consolidate rust major modes under `rustic-mode'. `rust-mode' derives
;; from `rust-ts-mode' when tree-sitter is enabled; clean up auto-mode-alist
;; so rustic wins, and load rustic right after rust-mode is defined.
(setq rust-mode-treesitter-derive (modulep! :lang rust +tree-sitter))

(after! rust-mode-treesitter
  (cl-callf2 delq 'rust-mode (get 'rust-ts-mode 'derived-mode-extra-parents))
  (put 'rust-mode 'derived-mode--all-parents nil)
  (put 'rust-ts-mode 'derived-mode--all-parents nil))

(cl-callf2 rassq-delete-all 'rust-mode auto-mode-alist)
(cl-callf2 rassq-delete-all 'rustic-mode auto-mode-alist)

(with-eval-after-load 'rust-mode
  (let (auto-mode-alist)
    (require 'rustic nil t)))

(leaf rust-mode
  :ensure t
  :config
  (setq rust-indent-method-chain t))

(leaf rustic
  :ensure t
  :mode ("\\.rs\\'" . rustic-mode)
  :preface
  ;; HACK: `rustic' sets up some things too early. Disable it and let the
  ;;   respective modules standardize how they're initialized.
  (setq rustic-lsp-client nil)
  (after! rustic-lsp
    (remove-hook 'rustic-mode-hook 'rustic-setup-lsp))
  (after! rustic-flycheck
    (remove-hook 'rustic-mode-hook #'flycheck-mode)
    (remove-hook 'rustic-mode-hook #'flymake-mode-off))
  :init
  ;; HACK: `rustic-babel' must be loaded in order for org-babel to work, so
  ;; alias it lazily once org-src loads.
  (after! org-src
    (defalias 'org-babel-execute:rust #'org-babel-execute:rustic)
    (add-to-list 'org-src-lang-modes '("rust" . rustic)))
  :config
  ;; Leave automatic reformatting to the :editor format module.
  (setq rustic-babel-format-src-block nil
        rustic-format-trigger nil)

  (setq rustic-lsp-client 'lsp-mode)
  (add-hook 'rustic-mode-hook #'rustic-setup-lsp)

  (when (modulep! :tools lsp -eglot)
    ;; HACK: Add the @scturtle fix for signatures on hover in LSP mode.
    (defun +rust--dont-cache-results-from-ra-a (&rest _)
      (when (derived-mode-p 'rust-mode 'rust-ts-mode)
        (setq lsp--hover-saved-bounds nil)))
    (advice-add #'lsp-eldoc-function :after #'+rust--dont-cache-results-from-ra-a))

  ;; HACK: If lsp/eglot isn't available, rustic attempts to install lsp-mode
  ;;   via package.el. Disable this behavior to avoid errors.
  (defun +rust--dont-install-packages-a (&rest _)
    (message "No LSP server running"))
  (advice-add #'rustic-install-lsp-client-p :override #'+rust--dont-install-packages-a)

  (general-define-key
   :keymaps 'rustic-mode-map
   :states '(normal visual motion)
   :prefix luna-localleader-key
   "ba" '(#'+rust/cargo-audit :wk "cargo audit")
   "bb" '(rustic-cargo-build :wk "cargo build")
   "bB" '(rustic-cargo-bench :wk "cargo bench")
   "bc" '(rustic-cargo-check :wk "cargo check")
   "bC" '(rustic-cargo-clippy :wk "cargo clippy")
   "bd" '(rustic-cargo-build-doc :wk "cargo doc")
   "bD" '(rustic-cargo-doc :wk "cargo doc --open")
   "bf" '(rustic-cargo-fmt :wk "cargo fmt")
   "bn" '(rustic-cargo-new :wk "cargo new")
   "bo" '(rustic-cargo-outdated :wk "cargo outdated")
   "br" '(rustic-cargo-run :wk "cargo run")
   "ta" '(rustic-cargo-test :wk "cargo test all")
   "tt" '(rustic-cargo-current-test :wk "cargo test current")))

;;; lang/python.el ends here