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

(defconst luna-leader-key "SPC")
(defconst luna-localleader-key "SPC m")

(defvar lunaris--dir (file-name-directory (or load-file-name buffer-file-name "")))
(defalias 'luna-user-dir (lambda () lunaris--dir))

(defmacro after! (feature &rest body)
  "Run BODY after FEATURE loads. FEATURE is bound to a runtime variable so the
byte-compiler can't resolve it to a file and eager-load it mid-compile (which
would cycle when a module file shares its feature name with a package, e.g.
lang/latex.el vs auctex's `latex')."
  (declare (indent defun))
  `(let ((feat ',feature))
     (if (featurep feat)
         (funcall (lambda () ,@body))
       (eval-after-load feat (lambda () ,@body)))))

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
  "Define advice SYMBOL on one or more targets:
  (defadvice! name (args) :before 'fn ...)          ; single
  (defadvice! name (args) :before '(fn1 fn2) ...)   ; multiple"
  (declare (indent defun))
  (let ((where (car body))
        (targets (cadr body))
        (body (cddr body)))
    (unless (keywordp where)
      (error "defadvice! expects (name (args) :where 'target ...)"))
    (let ((targets
           (cond ((and (listp targets) (eq (car targets) 'quote))
                  (cadr targets))
                 ((and (listp targets) (eq (car targets) 'function))
                  (list (cadr targets)))
                 (t (list targets)))))
      `(progn
         (defun ,symbol ,arglist ,@body)
         ,@(mapcar (lambda (tgt) `(advice-add ',tgt ,where #',symbol))
                   targets)))))

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

;;; map! → general, per-state, error-swallowing. Supports doom syntax incl.
;;; nested groups: (:when cond ...), (:prefix (label . key) key cmd ...).
(defun lunaris--map!-emit (states keymaps prefix defs)
  (unless (or states keymaps)
    (setq states '(normal visual motion insert emacs)))
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
         (error nil)))))

(defun lunaris--map!-collect (args &optional prefix states keymaps)
  "Parse map! ARGS into specs (list of (prefix keymaps states defs)).
Nested (:prefix (label . key) body...) augments PREFIX (leader + key)."
  (let ((specs nil) (defs nil))
    (while args
      (let ((tok (car args)))
        (cond
         ((and (listp tok) (eq (car tok) :when))
          (if (eval (cadr tok))
              (setq args (append (cddr tok) (cdr args)))
            (setq args (cdr args))))
         ((and (listp tok) (memq (car tok) '(:prefix :map :keymaps :leader)))
          (when defs
            (push (list prefix keymaps states (nreverse defs)) specs)
            (setq defs nil))
          (let ((kind (car tok)))
            (pcase kind
              (:prefix
               (let* ((p (cadr tok))
                      (k (if (and (consp p) (cdr p)) (cdr p) p))
                      (inner (cddr tok)))
                 (setq specs
                       (append specs
                               (lunaris--map!-collect inner
                                                      (if prefix (concat prefix " " k) k)
                                                      states keymaps))))
               (setq args (cdr args)))
              (:leader
               (setq prefix luna-leader-key)
               (setq args (cdr args)))
              (:map
               (setq keymaps (list (cadr tok)))
               (setq args (cddr args)))
              (:keymaps
               (setq keymaps (cadr tok))
               (setq args (cddr args))))))
         ((keywordp tok)
          (pcase tok
            ((or :n :normal) (setq states '(normal)))
            (:i (setq states '(insert emacs)))
            (:v (setq states '(visual)))
            (:m (setq states '(motion)))
            (:gi (setq states '(normal insert visual emacs)))
            (:g  (setq states '(normal visual motion)))
            (:nv (setq states '(normal visual)))
            (:leader (setq prefix luna-leader-key))
            (:prefix (setq prefix (cadr args)))
            (:map (setq keymaps (list (cadr args))))
            (:keymaps (setq keymaps (cadr args)))
            (_ nil))
          (setq args (if (memq tok '(:prefix :map :keymaps)) (cddr args) (cdr args))))
         (t
          (push (cons tok (cadr args)) defs)
          (setq args (cddr args))))))
    (when defs
      (push (list prefix keymaps states (nreverse defs)) specs))
    (nreverse specs)))

(defun lunaris--map!-handle (args)
  (let ((specs (lunaris--map!-collect args)))
    `(progn
       ,@(mapcar (lambda (spec)
                   (lunaris--map!-emit (nth 2 spec) (nth 1 spec)
                                       (nth 0 spec) (nth 3 spec)))
                 specs))))

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

;;; Stage-2 background load — after the dashboard/frame is up, warm the
;;; commonly used deferred packages in the background so first use is instant.
(defvar lunaris-stage-2-packages
  '(vertico orderless consult marginalia nerd-icons
    corfu cape
    emacsql-sqlite magit lsp-mode lsp-ui
    denote denote-sequence denote-journal consult-denote
    org-modern org-appear org-super-agenda
    smartparens editorconfig popper ultra-scroll evil-goggles
    ligature unicode-fonts flycheck dirvish mistty eww
    hl-todo indent-bars diff-hl winum persp-mode)
  "Features required by `lunaris-stage-2' in the background.")

(defvar lunaris--tree-queue nil
  "Remaining module files for chunked stage-2 loading.")

(defun lunaris-stage-2 ()
  "Stage 2: load the framework modules (doom ports) in the background, a few
files per idle tick so typing is never blocked. Layout: one directory per
manifest group (e.g. framework/lang/); `<group>.el` inside is the group-level
file (always loaded when the group is enabled), any other `<submodule>.el` is
loaded only when `(modulep! :<group> <submodule>)` is t."
  (let ((dir (expand-file-name "framework" (luna-user-dir)))
        (q nil) (group-files nil))
    (lunaris--cache-check-build-id (expand-file-name "lisp" lunaris-cache-dir))
    (lunaris--cache-read-blacklist (expand-file-name "lisp" lunaris-cache-dir))
    (dolist (file (directory-files-recursively dir "\\.el$"))
      (let* ((base (file-name-nondirectory file))
             (group (intern (concat ":"
                                    (file-name-nondirectory
                                     (directory-file-name
                                      (file-name-directory file))))))
             (sub (file-name-base base)))
        (when (and (not (string-prefix-p "_" base))
                   (not (string-prefix-p "." base))
                   (not (string-prefix-p "#" base))
                   (not (string-suffix-p "~" base))
                   (assq group lunaris--manifest)
                   (or (string= sub (substring (symbol-name group) 1))
                       (assq (intern sub) (cdr (assq group lunaris--manifest)))))
          (if (string= sub (substring (symbol-name group) 1))
              (push file group-files)
            (push file q)))))
    (setq lunaris--tree-queue
          (append (sort group-files #'string<)
                  (sort q #'string<))))
  (lunaris-stage-2-chunk))

(defun lunaris-stage-2-now ()
  "Load the whole module tree synchronously (tests / eager use)."
  (lunaris-stage-2)
  (while lunaris--tree-queue
    (lunaris-stage-2-chunk)))

(defun lunaris-stage-2-chunk ()
  "Load up to 4 module files per idle tick; finish with evil-collection."
  (let ((n 0)
        (cache (expand-file-name "lisp" lunaris-cache-dir)))
    (while (and lunaris--tree-queue (< n 4))
      (let ((file (car lunaris--tree-queue)))
        (setq lunaris--tree-queue (cdr lunaris--tree-queue))
        (when file
          (condition-case err
              (lunaris--load-cached file cache)
            (error (lunaris-log "stage-2 %s: %s" file (error-message-string err))))))
      (setq n (1+ n)))
    (if lunaris--tree-queue
        (run-with-idle-timer 0.1 nil #'lunaris-stage-2-chunk)
      ;; all loaded; wire evil-collection once
      (when (and (require 'evil-collection nil t) (featurep 'evil))
        (condition-case err
            (evil-collection-init)
          (error (lunaris-log "evil-collection-init: %s" (error-message-string err))))))))

;;; =========================================================================
;;; 5. helpers (doom-core ports)
;;; =========================================================================

(defun lunaris-log (&rest args)
  (when (bound-and-true-p lunaris-debug)
    (apply #'message args)))

(defalias 'luna-log #'lunaris-log
  "Doom-compat alias for `lunaris-log'.")

(defvar lunaris-debug nil)

(defvar lunaris-cache-dir
  (expand-file-name "lunatix-emacs"
                    (or (getenv "XDG_CACHE_HOME")
                        (expand-file-name ".cache"
                                          (or (getenv "HOME") "/tmp"))))
  "Cache dir for byte-compiled modules and runtime state (XDG, not the
config tree).")

;;; Import-tree loader with byte-compile cache — interpreted 18k lines of
;;; modules is the startup killer; load .elc from the cache instead. First run
;;; compiles (slow), subsequent runs load compiled (fast).
(defvar lunaris-core-files
  '("evil-config.el" "general-config.el" "which-key-config.el"
    "theme-config.el" "keybindings-config.el" "config/personal.el")
  "Files loaded at startup (stage 1). Everything else loads in stage 2.")

(defvar lunaris--loaded-files nil
  "Absolute paths of config/module files already loaded (dedup registry).")

(defun lunaris--cache-build-id ()
  "Identity of the current package set, for cache invalidation.
`just switch' can change the package store while leaving source files
untouched; mtime alone would keep stale .elc around. Key on the
emacsWithPackages site-lisp env var (a per-build store hash, stable across
runs) — hashing the runtime load-path is unstable (its elpa enumeration
varies run to run), which wiped + recompiled the cache every startup."
  (md5 (or (getenv "emacsWithPackages_siteLisp")
           (getenv "EMACSLOADPATH")
           (mapconcat #'identity
                      (sort (delete-dups
                             (seq-filter (lambda (d)
                                           (or (string-match-p "elpa" d)
                                               (string-match-p "emacs-packages-deps" d)))
                                         load-path))
                            #'string<)
                      ","))))

(defun lunaris--cache-check-build-id (cache)
  "Wipe CACHE's .elc when the package store changed (stamp mismatch)."
  (make-directory cache t)
  (let ((stamp (expand-file-name "BUILD-ID" cache))
        (id (lunaris--cache-build-id)))
    (unless (and (file-exists-p stamp)
                 (string= id (string-trim
                              (with-temp-buffer
                                (insert-file-contents stamp)
                                (buffer-string)))))
      (dolist (f (directory-files cache t "\\.elc$"))
        (ignore-errors (delete-file f)))
      (with-temp-file stamp (insert id)))))

(defvar lunaris--no-compile-files nil
  "Base names of files to load from source (byte-compile is slow/unreliable
for them: native-comp on this laptop hangs). Auto-populated when a compile
fails; persisted in CACHE/NOT-COMPILED.")

(defun lunaris--no-byte-compile-p (file)
  "Non-nil when FILE carries a `no-byte-compile' header or is blacklisted."
  (or (member (file-name-nondirectory file) lunaris--no-compile-files)
      (with-temp-buffer
        (insert-file-contents file nil 0 300)
        (goto-char (point-min))
        (search-forward "no-byte-compile" nil t))))

(defun lunaris--cache-read-blacklist (cache)
  "Load the NOT-COMPILED blacklist from CACHE."
  (let ((f (expand-file-name "NOT-COMPILED" cache)))
    (when (file-exists-p f)
      (setq lunaris--no-compile-files
            (split-string (string-trim
                           (with-temp-buffer
                             (insert-file-contents f)
                             (buffer-string))))))))

(defun lunaris--cache-add-blacklist (cache base)
  "Persist BASE in CACHE/NOT-COMPILED (skip byte-compile next runs)."
  (let ((f (expand-file-name "NOT-COMPILED" cache)))
    (with-temp-file f
      (dolist (b (sort (delete-dups (cons base lunaris--no-compile-files))
                       #'string<))
        (insert b "\n")))))

(defun lunaris--load-cached (file cache)
  "Compile FILE into CACHE (if stale) and load the .elc.
Dedups by file path (doom-style: module files never provide their own
feature, so `featurep' can't be used and must not be pre-claimed)."
  (let ((file (expand-file-name file)))
    (unless (member file lunaris--loaded-files)
      (push file lunaris--loaded-files)
      (if (lunaris--no-byte-compile-p file)
          ;; source-load: byte/native-compilation of this file is slow or
          ;; unreliable (native-comp hangs on this laptop for some modules)
          (condition-case err
              (load file nil :nomessage)
            (error (lunaris-log "Failed loading %s: %s" file (error-message-string err))))
        (let* ((base (file-name-nondirectory file))
               (cache-elc (expand-file-name (concat base "c") cache))
               (stale (or (not (file-exists-p cache-elc))
                          (time-less-p
                           (file-attribute-modification-time (file-attributes cache-elc))
                           (file-attribute-modification-time (file-attributes file))))))
          (when stale
            ;; Compile via a unique temp then atomically rename into place: the
            ;; daemon, client frames and test runs share the cache, so compiling
            ;; the shared cache-src in place lets a concurrent reader see a
            ;; half-written file ("End of file during parsing").
            (let ((tmp (expand-file-name
                        (format ".tmp-%s-%d.el" base (emacs-pid)) cache))
                  (tmp-elc (expand-file-name
                            (format ".tmp-%s-%d.elc" base (emacs-pid)) cache)))
              (condition-case err
                  (progn
                    (copy-file file tmp t)
                    (let ((debug-on-error nil))
                      ;; compiler signals (e.g. eager macro-expansion cycle) must
                      ;; hit our handler, not the user's debugger
                      (byte-compile-file tmp))
                    (when (file-exists-p tmp-elc)
                      (rename-file tmp-elc cache-elc t))
                    (delete-file tmp))
                (error
                 ;; a module whose feature collides with a package's eager-load
                 ;; (e.g. php/latex) can still trip the compiler; fall back to
                 ;; loading the source so the module works.
                 (lunaris-log "compile failed %s (%s); loading source" file
                              (error-message-string err))
                 (lunaris--cache-add-blacklist cache base)
                 (dolist (f (list tmp tmp-elc)) (ignore-errors (delete-file f)))
                 (load file nil :nomessage)
                 (setq cache-elc nil)))))
          (when cache-elc
            (condition-case err
                (load cache-elc nil :nomessage)
              (error (lunaris-log "Failed loading %s: %s" file (error-message-string err))))))))))

(defun lunaris-load-core (dir)
  "Load every .el under DIR (user config), skipping `_`/lock files.
general-config loads first: it defines the `lunatix-leader' macro that
keybindings-config (and friends) expand at compile time."
  (let ((cache (expand-file-name "lisp" lunaris-cache-dir)))
    (lunaris--cache-check-build-id cache)
    (lunaris--cache-read-blacklist cache)
    (let ((files (directory-files-recursively dir "\\.el$")))
      (dolist (file (cons (expand-file-name "general-config.el" dir) files))
        (when (file-exists-p file)
          (let ((base (file-name-nondirectory file)))
            (unless (or (string-prefix-p "_" base)
                        (string-prefix-p "." base)
                        (string-prefix-p "#" base)
                        (string-suffix-p "~" base))
              (lunaris--load-cached file cache))))))))

(defun lunaris-load-tree (dir)
  "Load every .el under DIR (recursive), skipping `_`-prefixed paths and
already-loaded (stage-1) features. Byte-compiles into the cache on first run."
  (let ((cache (expand-file-name "lisp" lunaris-cache-dir)))
    (make-directory cache t)
    (dolist (file (directory-files-recursively dir "\\.el$"))
      (let ((base (file-name-nondirectory file)))
        (unless (or (string-prefix-p "_" base)
                    (string-prefix-p "." base)   ; lock files .#foo.el
                    (string-prefix-p "#" base)
                    (string-suffix-p "~" base))
          (lunaris--load-cached file cache))))))

(defun luna-region-active-p ()
  (and (region-active-p) (> (region-end) (region-beginning))))

(defun luna-point-in-comment-p (&optional pos)
  (let* ((pos (or pos (point)))
         (beg (save-excursion (goto-char pos) (nth 8 (syntax-ppss)))))
    (and beg (< beg pos))))

(defun luna-project-root (&optional path)
  "Project root via projectile (falls back to nil outside a project)."
  (condition-case nil
      (projectile-project-root
       (if path (file-name-directory path) default-directory))
    (error nil)))

(defun luna-call-process (&rest args)
  (with-temp-buffer
    (cons (apply #'call-process (car args) nil t nil (cdr args))
          (buffer-string))))

(defun luna-call-process-in (destdir &rest args)
  (let ((default-directory destdir))
    (apply #'luna-call-process args)))

(defun luna-temp-buffer-p (buffer)
  (string-prefix-p "*" (buffer-name buffer)))

(defun luna-real-buffer-p (buffer)
  (not (luna-temp-buffer-p buffer)))

(defun luna-fallback-buffer ()
  (get-buffer-create "*scratch*"))

;;; Font zoom (doom): frame-wide font size, buffer-independent, resettable
(defvar luna--initial-font-height nil
  "Default frame font height, captured at startup.")

(defun doom/increase-font-size (&optional inc)
  "Increase the frame font size by INC*10 (default 10)."
  (interactive "p")
  (unless luna--initial-font-height
    (setq luna--initial-font-height (face-attribute 'default :height)))
  (let ((cur (face-attribute 'default :height)))
    (set-face-attribute 'default nil :height (+ cur (* 10 (or inc 1))))))

(defun doom/decrease-font-size (&optional inc)
  "Decrease the frame font size by INC*10 (default 10)."
  (interactive "p")
  (doom/increase-font-size (- (or inc 1))))

(defun doom/reset-font-size ()
  "Reset the frame font size to the configured default."
  (interactive)
  (when luna--initial-font-height
    (set-face-attribute 'default nil :height luna--initial-font-height)))

(run-with-idle-timer 1 nil
                     (lambda ()
                       (setq luna--initial-font-height (face-attribute 'default :height))))

(defun luna-disable-line-numbers-h ()
  (display-line-numbers-mode -1))

(defun luna-mark-buffer-as-real-h (&optional buffer)
  (with-current-buffer (or buffer (current-buffer)) nil))

(defun luna-profile-state-dir (&rest dirs)
  "Base state dir, optionally joined with DIRS (doom-compat: `doom-state-dir').
All profile dirs collapse to the single XDG cache dir. Leading `t' (port
artifact) is dropped."
  (apply #'file-name-concat lunaris-cache-dir
         (seq-remove (lambda (d) (or (eq d t) (null d))) dirs)))
(defun luna-profile-cache-dir (&rest dirs)
  (apply #'file-name-concat lunaris-cache-dir
         (seq-remove (lambda (d) (or (eq d t) (null d))) dirs)))
(defun luna-profile-data-dir (&rest dirs)
  (apply #'file-name-concat lunaris-cache-dir
         (seq-remove (lambda (d) (or (eq d t) (null d))) dirs)))
(defun luna-context-p (&rest _) nil)
(defun luna-system-cpus (&rest _) (num-processors))
(defun luna-require (feature &optional _file _noerror) (require feature))

(defvar luna-escape-hook nil)
(defvar luna-first-input-hook nil)
(defvar luna-first-buffer-hook nil)
(defvar luna-first-file-hook nil)
(defvar luna-first-buffer nil)
(defvar luna-first-file nil)
(defvar luna-first-input nil)
(defvar luna-switch-buffer-hook nil)
(defvar luna-switch-window-hook nil)
(defvar luna-load-theme-hook nil)
(defvar luna-init-ui-hook nil)
(defvar luna-after-modules-config-hook nil)
(defvar luna-modeline-spc nil)
(defvar luna-use-helpful-a t)
(defvar luna-quit-messages nil)
(defvar luna-profile-state-dir nil)
(defvar luna-profile-cache-dir nil)
(defvar luna-profile-data-dir nil)
(defvar luna-cache-dir nil)
(defvar luna-inhibit-local-var-hooks nil)

;;; =========================================================================
;;; 6. module health check — doom doctor-style
;;; =========================================================================
;;; Each group dir may ship a `doctor.el' (doom's per-module doctor.el,
;;; collapsed to one file per group) whose top-level forms gate on
;;; `(modulep! :<group> <module>)' and report via `ok!'/`warn!'/`error!'.
;;; `lunaris-doctor' loads every enabled group's doctor.el standalone (no
;;; modules loaded, like `bin/doom doctor') and prints a grouped report.
;;; doctor.el is never loaded by stage-2 (its feature `doctor' matches no
;;; manifest submodule).

(defvar lunaris--doctor-current nil
  "Group (keyword) whose doctor.el is being evaluated; report context.")

(defvar lunaris--doctor-reports nil
  "Accumulated reports: (GROUP SEVERITY . MESSAGE).")

(defmacro ok! (&rest args)
  "Record a passing check (message from ARGS)."
  `(lunaris--doctor-report 'ok (format ,@args)))

(defmacro warn! (&rest args)
  "Record a non-fatal problem (message from ARGS)."
  `(lunaris--doctor-report 'warn (format ,@args)))

(defmacro error! (&rest args)
  "Record a fatal problem (message from ARGS)."
  `(lunaris--doctor-report 'error (format ,@args)))

(defun lunaris--doctor-report (severity message)
  (push (list lunaris--doctor-current severity message) lunaris--doctor-reports))

(defun lunaris--doctor-face (severity)
  (pcase severity
    ('ok    'success)
    ('warn  'warning)
    ('error 'error)))

(defun lunaris--doctor-render ()
  "Print accumulated doctor reports to *Messages*, doom-doctor-style."
  (let ((by-module (seq-group-by #'car lunaris--doctor-reports)))
    (dolist (group-reports by-module)
      (let ((group (car group-reports)))
        (princ (format "\n== %s ==\n" (symbol-name group))))
      (dolist (rep (cdr group-reports))
        (let ((severity (nth 1 rep))
              (message (nth 2 rep)))
          (princ (format "  %s %s\n"
                         (propertize (upcase (symbol-name severity))
                                     'face (lunaris--doctor-face severity))
                         message)))))))

(defun lunaris-doctor ()
  "Health-check every enabled module group, doom-doctor-style.
Loads each enabled group's framework/<group>/doctor.el standalone and prints a
per-module report of `ok!'/`warn!'/`error!' findings."
  (interactive)
  (setq lunaris--doctor-reports nil)
  (let ((dir (expand-file-name "framework" (luna-user-dir))))
    (dolist (group (mapcar #'car lunaris--manifest))
      (let ((doctor (expand-file-name "doctor.el" (expand-file-name (substring (symbol-name group) 1) dir))))
        (when (file-exists-p doctor)
          (let ((lunaris--doctor-current group))
            (condition-case err
                (load doctor nil :nomessage)
              (error
               (lunaris--doctor-report group 'error
                                       (format "doctor.el failed: %s" (error-message-string err))))))))))
  (lunaris--doctor-render))

(defun lunaris-doctor-count (&optional severity)
  "Count doctor reports (all, or of SEVERITY)."
  (if severity
      (cl-count-if (lambda (r) (eq (nth 1 r) severity)) lunaris--doctor-reports)
    (length lunaris--doctor-reports)))


;;; Legacy doom-* aliases (renamed to luna-* for a unified prefix; kept
;;; so ported code that still references the old names keeps working).
(defalias 'doom-user-dir #'luna-user-dir)
(defalias 'doom-log #'luna-log)
(defalias 'doom-region-active-p #'luna-region-active-p)
(defalias 'doom-point-in-comment-p #'luna-point-in-comment-p)
(defalias 'doom-project-root #'luna-project-root)
(defalias 'doom-call-process #'luna-call-process)
(defalias 'doom-call-process-in #'luna-call-process-in)
(defalias 'doom-temp-buffer-p #'luna-temp-buffer-p)
(defalias 'doom-real-buffer-p #'luna-real-buffer-p)
(defalias 'doom-fallback-buffer #'luna-fallback-buffer)
(defalias 'doom-disable-line-numbers-h #'luna-disable-line-numbers-h)
(defalias 'doom-mark-buffer-as-real-h #'luna-mark-buffer-as-real-h)
(defalias 'doom-profile-state-dir #'luna-profile-state-dir)
(defalias 'doom-profile-cache-dir #'luna-profile-cache-dir)
(defalias 'doom-profile-data-dir #'luna-profile-data-dir)
(defalias 'doom-context-p #'luna-context-p)
(defalias 'doom-system-cpus #'luna-system-cpus)
(defalias 'doom-require #'luna-require)
(defvaralias 'doom-leader-key 'luna-leader-key)
(defvaralias 'doom-localleader-key 'luna-localleader-key)
(defvaralias 'doom--initial-font-height 'luna--initial-font-height)
(defvaralias 'doom-escape-hook 'luna-escape-hook)
(defvaralias 'doom-first-input-hook 'luna-first-input-hook)
(defvaralias 'doom-first-buffer-hook 'luna-first-buffer-hook)
(defvaralias 'doom-first-file-hook 'luna-first-file-hook)
(defvaralias 'doom-first-buffer 'luna-first-buffer)
(defvaralias 'doom-first-file 'luna-first-file)
(defvaralias 'doom-first-input 'luna-first-input)
(defvaralias 'doom-switch-buffer-hook 'luna-switch-buffer-hook)
(defvaralias 'doom-switch-window-hook 'luna-switch-window-hook)
(defvaralias 'doom-load-theme-hook 'luna-load-theme-hook)
(defvaralias 'doom-init-ui-hook 'luna-init-ui-hook)
(defvaralias 'doom-after-modules-config-hook 'luna-after-modules-config-hook)
(defvaralias 'doom-modeline-spc 'luna-modeline-spc)
(defvaralias 'doom-use-helpful-a 'luna-use-helpful-a)
(defvaralias 'doom-quit-messages 'luna-quit-messages)
(defvaralias 'doom-cache-dir 'luna-cache-dir)
(defvaralias 'doom-inhibit-local-var-hooks 'luna-inhibit-local-var-hooks)

(provide 'lunaris)
;;; lunaris.el ends here
