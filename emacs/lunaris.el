;;; lunaris.el --- unified backend: my own leaf-style DSL + doom-compat +
;;; module manifest + tree loader. Everything "backend" lives here; config
;;; side (manifest.el + modules/) only uses the clean API below.
;;;  -*- lexical-binding: t; -*-

(require 'cl-lib)

;;; =========================================================================
;;; 1. leaf — package declaration DSL (leaf.el-style, recreated)
;;;    Defaults: :ensure t; auto-:defer t on :hook/:bind/:commands.
;;; =========================================================================

(defmacro leaf (name &rest args)
  "Declare package NAME with ARGS (use-package keywords).
Defaults: `:ensure t` unless given; auto-`:defer t` when `:hook`/`:bind`/
`:commands` present and no `:defer`/`:demand` given."
  (declare (indent defun))
  (let* ((has-demand (memq :demand args))
         (has-defer (memq :defer args))
         (auto-defer (and (not has-demand) (not has-defer)
                          (cl-some (lambda (k) (memq k args))
                                   '(:hook :bind :commands)))))
    `(use-package ,name
       ,@(unless (memq :ensure args) '(:ensure t))
       ,@(if auto-defer (append args '(:defer t)) args))))

;;; =========================================================================
;;; 2. doom-compat — macros/helpers ported from doom-emacs, absorbed here
;;; =========================================================================

(defconst doom-leader-key "SPC")
(defconst doom-localleader-key "SPC m")

(defalias 'doom-user-dir (lambda () (file-name-directory (or load-file-name ""))))

(defmacro after! (feature &rest body)
  "Run BODY after FEATURE loads."
  (declare (indent defun))
  `(with-eval-after-load ',feature ,@body))

(defmacro cmd! (&rest body)
  "Interactive lambda wrapping BODY."
  (declare (indent defun))
  `(lambda (&rest _) (interactive) ,@body))

(defmacro cmds! (pred &rest body)
  "Interactive lambda running BODY if PRED."
  (declare (indent defun))
  `(lambda (&rest _) (interactive) (when ,pred ,@body)))

(defmacro cmd!! (command &rest args)
  "Interactive lambda calling COMMAND with ARGS."
  (declare (indent defun))
  `(lambda (&rest _) (interactive) (funcall-interactively #',command ,@args)))

(defmacro defadvice! (symbol arglist &rest body)
  "Define advice SYMBOL on a target: (defadvice! name (args) :where 'fn ...)."
  (declare (indent defun))
  (let ((where (car body))
        (target (cadr body))
        (body (cddr body)))
    (unless (keywordp where)
      (error "defadvice! expects (name (args) :where 'target ...)"))
    `(progn
       (defun ,symbol ,arglist ,@body)
       (advice-add ,target ,where #',symbol))))

(defmacro setq-hook! (hooks &rest rest)
  "setq-local vars via hooks: (setq-hook! '(hook) var val ...)."
  (declare (indent defun))
  `(dolist (hook ,hooks)
     (add-hook hook (lambda () ,@(mapcar (lambda (spec)
                                           `(setq-local ,@spec))
                                         (cl-loop for (v val) on rest by #'cddr
                                                  collect (list v val)))))))

(defmacro add-hook! (hooks &rest body)
  "Add BODY as a function to each HOOK."
  (declare (indent defun))
  `(dolist (hook ,hooks)
     (add-hook hook (lambda () ,@body))))

(defmacro remove-hook! (hooks &rest body)
  "Remove BODY function from each HOOK."
  (declare (indent defun))
  `(dolist (hook ,hooks)
     (remove-hook hook (lambda () ,@body))))

;;; map! → general, per-state, error-swallowing
(defun lunaris--map!-handle (args)
  (let ((states nil) (keymaps nil) (prefix nil) (defs nil))
    (while args
      (let ((tok (car args)))
        (cond
         ((and (listp tok) (eq (car tok) :when))
          (if (eval (cadr tok))
              (setq args (append (cddr tok) (cdr args)))
            (setq args (cdr args))))
         ((keywordp tok)
          (pcase tok
            ((or :n :normal) (setq states '(normal)))
            (:i (setq states '(insert)))
            (:v (setq states '(visual)))
            (:m (setq states '(motion)))
            (:gi (setq states '(normal insert visual emacs)))
            (:g  (setq states '(normal visual motion)))
            (:nv (setq states '(normal visual)))
            (:leader (setq prefix doom-leader-key))
            (:prefix (setq prefix (cadr args)))
            (:map (setq keymaps (list (cadr args))))
            (:keymaps (setq keymaps (cadr args)))
            (_ nil))
          (setq args (if (memq tok '(:prefix :map :keymaps)) (cddr args) (cdr args))))
         (t
          (push (cons tok (cadr args)) defs)
          (setq args (cddr args))))))
    (unless (or states keymaps)
      (setq states '(normal visual motion insert emacs)))
    (let ((defs (nreverse defs)))
      (if keymaps
          `(condition-case nil
               (general-def :keymaps ',keymaps
                 ,@(cl-mapcan (lambda (p) (list (car p) (cdr p))) defs))
             (error nil))
        `(dolist (state ',states)
           (condition-case nil
               (general-def :states (list state)
                 ,@(when prefix `(:prefix ,prefix))
                 ,@(cl-mapcan (lambda (p) (list (car p) (cdr p))) defs))
             (error nil)))))))

(defmacro map! (&rest args)
  "Doom-style keybinding macro built on general."
  (declare (indent defun))
  (lunaris--map!-handle args))

;;; lbind — my own, easier keybinding DSL (doom map! reimagined). Compiles
;;; down to the same robust emitter as `map!` (per-state, error-swallowing).
;;;   (lbind :leader "x" #'cmd "y" #'cmd2)       ; SPC x, SPC y
;;;   (lbind :localleader "z" #'cmd)              ; SPC m z
;;;   (lbind :prefix "gd" "n" #'cmd)              ; g d n
;;;   (lbind :map dired-mode-map "a" #'cmd)       ; mode map
;;;   (lbind "C-x x" #'cmd)                       ; raw full key, no prefix
(defun lunaris--lbind->map! (args)
  "Translate lbind ARGS into map!-style tokens."
  (let (out)
    (while args
      (let ((tok (pop args)))
        (pcase tok
          (:leader (push :leader out))
          (:localleader (push :prefix out) (push "SPC m" out))
          (:prefix (push :prefix out) (push (pop args) out))
          (:states (pop args))               ; ignored: map! defaults all
          (:map (push :map out) (push (pop args) out))
          (:keymaps (push :keymaps out) (push (pop args) out))
          (:after nil)
          (_ (push tok out) (push (pop args) out)))))
    (nreverse out)))

(defmacro lbind (&rest args)
  "Declare keybindings with a flat, keyword-first DSL."
  (declare (indent defun))
  (lunaris--map!-handle (lunaris--lbind->map! args)))

;;; =========================================================================
;;; 3. manifest — (lunaris! :group (sub +flag) ...) single source of truth
;;; =========================================================================

(defvar lunaris--manifest nil
  "Enabled modules parsed from `lunaris!'. Alist group -> ((sub flags...)...).")

(defmacro lunaris! (&rest specs)
  "Declare enabled modules, doom!-style.
Usage: (lunaris! :completion (corfu +orderless) (vertico +icons)
                 :ui deft dashboard ...)"
  (declare (indent defun))
  (let ((result nil) (group nil) (entries nil))
    (dolist (spec specs)
      (cond ((keywordp spec)
             (when group (push (cons group (nreverse entries)) result))
             (setq group spec entries nil))
            ((and (symbolp spec) (not (keywordp spec)))
             (push (list spec) entries))
            ((and (listp spec) (symbolp (car spec)))
             (push (cons (car spec) (cdr spec)) entries))))
    (when group (push (cons group (nreverse entries)) result))
    `(setq lunaris--manifest ',(nreverse result))))

(defmacro modulep! (module &optional submodule &rest flags)
  "t when MODULE (and SUBMODULE/FLAGS, if given) is enabled.
Flag `-foo` means \"enabled unless foo\"; plain `foo` means \"enabled with foo\".
Bare-flag form `(modulep! +lsp)` is t when any enabled submodule carries it."
  (if (keywordp module)
      (let* ((entry (assq module lunaris--manifest))
             (enabled
              (and entry
                   (or (null submodule)
                       (let ((sub (assq submodule (cdr entry))))
                         (and sub
                              (cl-every
                               (lambda (f)
                                 (let* ((name (symbol-name f))
                                        (neg (string-prefix-p "-" name))
                                        (flag (intern (if neg (substring name 1) name))))
                                   (if neg
                                       (not (memq flag (cdr sub)))
                                     (memq f (cdr sub)))))
                               flags)))))))
        (if enabled t nil))
    ;; bare-flag form: true if any enabled submodule has this flag
    (let ((found (cl-some
                  (lambda (group)
                    (cl-some (lambda (entry) (memq module (cdr entry)))
                             (cdr group)))
                  lunaris--manifest)))
      (if found t nil))))

;;; =========================================================================
;;; 4. tree loader — import-tree over modules/, `_`-prefixed skipped
;;; =========================================================================

(defun lunaris-load-tree (dir)
  "Load every .el under DIR (recursive), skipping `_`-prefixed paths.
Files load alphabetically by path; deps must sort correctly (e.g.
general-config before keybindings-config)."
  (dolist (file (directory-files-recursively dir "\\.el$"))
    (unless (string-match-p "/_" file)
      (condition-case err
          (load file nil :nomessage)
        (error (lunaris-log "Failed loading %s: %s" file (error-message-string err)))))))

;;; Stage-2 background load — after the dashboard/frame is up, warm the
;;; commonly used deferred packages in the background so first use is instant.
(defvar lunaris-stage-2-packages
  '(vertico orderless consult marginalia nerd-icons nerd-icons-completion
    corfu cape magit forge lsp-mode lsp-ui
    denote denote-sequence denote-journal consult-denote
    org-modern org-appear org-super-agenda
    smartparens editorconfig popper ultra-scroll evil-goggles
    ligature unicode-fonts flycheck dirvish mistty eww)
  "Features required by `lunaris-stage-2' in the background.")

(defun lunaris-stage-2 ()
  "Load stage-2 packages in the background. Errors are logged, never fatal."
  (dolist (feature lunaris-stage-2-packages)
    (condition-case err
        (require feature nil t)
      (error (lunaris-log "stage-2 failed loading %S: %s" feature (error-message-string err))))))

;;; =========================================================================
;;; 5. helpers (doom-core ports)
;;; =========================================================================

(defun lunaris-log (&rest args)
  (when (bound-and-true-p lunaris-debug)
    (apply #'message args)))

(defalias 'doom-log #'lunaris-log
  "Doom-compat alias for `lunaris-log'.")

(defvar lunaris-debug nil)

(defun doom-region-active-p ()
  (and (region-active-p) (> (region-end) (region-beginning))))

(defun doom-point-in-comment-p (&optional pos)
  (let* ((pos (or pos (point)))
         (beg (save-excursion (goto-char pos) (nth 8 (syntax-ppss)))))
    (and beg (< beg pos))))

(defun doom-project-root (&optional path)
  (let ((default-directory (if path (file-name-directory path) default-directory)))
    (project-root (project-current t))))

(defun doom-call-process (&rest args)
  (with-temp-buffer
    (cons (apply #'call-process (car args) nil t nil (cdr args))
          (buffer-string))))

(defun doom-call-process-in (destdir &rest args)
  (let ((default-directory destdir))
    (apply #'doom-call-process args)))

(defun doom-temp-buffer-p (buffer)
  (string-prefix-p "*" (buffer-name buffer)))

(defun doom-real-buffer-p (buffer)
  (not (doom-temp-buffer-p buffer)))

(defun doom-fallback-buffer ()
  (get-buffer-create "*scratch*"))

(defun doom-disable-line-numbers-h ()
  (display-line-numbers-mode -1))

(defun doom-mark-buffer-as-real-h (&optional buffer)
  (with-current-buffer (or buffer (current-buffer)) nil))

(defun doom-profile-state-dir (&rest _) user-emacs-directory)
(defun doom-profile-cache-dir (&rest _) (expand-file-name ".cache" user-emacs-directory))
(defun doom-profile-data-dir (&rest _) (expand-file-name ".local" user-emacs-directory))
(defun doom-context-p (&rest _) nil)
(defun doom-system-cpus (&rest _) (num-processors))
(defun doom-require (feature &optional _file _noerror) (require feature))

(defvar doom-escape-hook nil)
(defvar doom-first-input-hook nil)
(defvar doom-first-buffer-hook nil)
(defvar doom-first-file-hook nil)
(defvar doom-first-buffer nil)
(defvar doom-first-file nil)
(defvar doom-first-input nil)
(defvar doom-switch-buffer-hook nil)
(defvar doom-switch-window-hook nil)
(defvar doom-load-theme-hook nil)
(defvar doom-init-ui-hook nil)
(defvar doom-after-modules-config-hook nil)
(defvar doom-modeline-spc nil)
(defvar doom-use-helpful-a t)
(defvar doom-quit-messages nil)
(defvar doom-profile-state-dir nil)
(defvar doom-profile-cache-dir nil)
(defvar doom-profile-data-dir nil)
(defvar doom-cache-dir nil)
(defvar doom-inhibit-local-var-hooks nil)

(provide 'lunaris)
;;; lunaris.el ends here
