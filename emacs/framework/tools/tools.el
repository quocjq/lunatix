;;; tools/tools.el --- doom :tools group file (shared helpers)  -*- lexical-binding: t; -*-
;;; Module files in this dir are gated by `(modulep! :tools <module>)'; this
;;; group file always loads first.

;;; tools-config.el --- external tool integrations (doom :tools set)  -*- lexical-binding: t; -*-
;;; Commentary:
;; Ported from doom-modules/modules/tools/{biblio,docker,editorconfig,eval,lookup,
;; lsp,magit,pass,pdf,tree-sitter,upload}.  Uses the lunatix-doom compat layer
;; (after!, map!, defadvice!, modulep!, add-hook!, etc).

(require 'cl-lib)
(require 'subr-x)

;;
;;; Doom helpers referenced by the ported configs but missing from the compat
;;; layer.  Popup rules and debug-var hooks are no-ops: doom's popup framework
;;; is not ported (plain `display-buffer' is used instead), and formatting is
;;; handled by apheleia (see editor-config.el).

(defmacro set-popup-rule! (&rest _)
  "Doom-compat: no-op.  Doom's popup framework isn't ported."
  nil)

(defmacro set-popup-rules! (&rest _)
  "Doom-compat: no-op.  Doom's popup framework isn't ported."
  nil)

(defmacro set-debug-var! (&rest _)
  "Doom-compat: no-op.  Doom's debug-var hooks aren't ported."
  nil)

(defmacro set-formatter! (&rest _)
  "Doom-compat: no-op.  Formatting is handled by apheleia."
  nil)

(defmacro dlet (bindings &rest body)
  "Doom-compat: dynamically bind each var in BINDINGS in BODY.
A bare symbol binds that variable to nil."
  (declare (indent 1))
  (let ((normalized (mapcar (lambda (b) (if (symbolp b) (list b nil) b))
                            bindings)))
    `(cl-progv ',(mapcar #'car normalized)
         (list ,@(mapcar #'cadr normalized))
       ,@body)))

(defmacro letf! (bindings &rest body)
  "Doom-compat: buffer-local `cl-letf'. `(#'FN ...)' bindings act on FN's
function cell — raw `cl-letf' treats `(function FN)' as a variable place and
calls `(setf function)' (void) / sets FN as a variable."
  (declare (indent 1))
  `(cl-letf ,(mapcar (lambda (b)
                       (let ((place (car b))
                             (val (cdr b)))
                         (if (and (listp place) (eq (car place) 'function)
                                  (symbolp (cadr place)))
                             (cons (list 'symbol-function
                                         (list 'quote (cadr place)))
                                   val)
                           b)))
                     bindings)
     ,@body))

(defmacro defer-until! (condition &rest body)
  "Doom-compat: run BODY once CONDITION returns non-nil."
  (declare (indent 1))
  (let ((timer (gensym "defer-until-")))
    `(let ((,timer nil))
       (setq ,timer
             (run-with-idle-timer
              0.5 1
              (lambda ()
                (when ,condition
                  (cancel-timer ,timer)
                  ,@body)))))))

(defvar doom-switch-frame-hook nil
  "Doom-compat: hook run when the selected frame changes.")

(defvar luna-real-buffer-functions nil
  "Doom-compat: list of functions that classify a buffer as \"real\".")

(defun doom-region-beginning () (region-beginning))
(defun doom-region-end () (region-end))

(defun doom-region (&optional beg end)
  "Doom-compat: return the active region's text, or nil."
  (when (luna-region-active-p)
    (buffer-substring-no-properties (or beg (region-beginning))
                                    (or end (region-end)))))

(defun doom-thing-at-point-or-region (&optional thing)
  "Doom-compat: return the active region or THING at point."
  (let ((regionp (luna-region-active-p)))
    (if regionp
        (buffer-substring-no-properties (region-beginning) (region-end))
      (when-let* ((thing (or thing 'symbol))
                  ((thing-at-point thing)))
        (string-trim (substring-no-properties (thing-at-point thing)))))))

(defun doom-pcre-quote (string)
  "Doom-compat: quote STRING as a PCRE literal."
  (concat "\\Q" (replace-regexp-in-string "\\E" "\\E\\Q" string) "\\E"))

(defun doom-project-p (&optional path)
  "Doom-compat: non-nil if PATH is inside a project."
  (ignore-errors (luna-project-root path)))

(defun doom-visible-buffers (&optional frame _all-frames)
  "Doom-compat: buffers currently visible in FRAME's windows."
  (cl-remove-duplicates
   (mapcar #'window-buffer (window-list (or frame (selected-frame))))
   :test #'eq))

(defun doom-buffers-in-mode (&rest modes)
  "Doom-compat: live buffers whose major-mode derives from MODES."
  (cl-remove-if-not
   (lambda (buffer)
     (apply #'provided-mode-derived-p (buffer-local-value 'major-mode buffer) modes))
   (buffer-list)))

(defun doom-lookup-key (key &optional _state)
  "Doom-compat: command bound to KEY, evil-state aware."
  (if (and (bound-and-true-p evil-local-mode)
           (not (memq evil-state '(emacs insert))))
      (or (evil-lookup-key (current-global-map) key)
          (key-binding key))
    (key-binding key)))

;;
;;; tools/tree-sitter helpers (also used by the docker module)
;;; treesit is built into Emacs 30; the backports below (from doom's
;;; compat-30.el) cover the pieces that only exist in Emacs 31.

(defcustom treesit-auto-install-grammar 'ask
  "Whether to install tree-sitter language grammar libraries when needed."
  :type '(choice (const :tag "Never install grammar libraries" never)
                 (const :tag "Always automatically install grammar libraries" always)
                 (const :tag "Ask whether to install missing grammar libraries" ask))
  :version "31.1"
  :group 'treesit)

(defun treesit-ensure-installed (lang)
  "Ensure that the grammar library for LANG is installed."
  (or (treesit-ready-p lang t)
      (when (or (eq treesit-auto-install-grammar 'always)
                (and (eq treesit-auto-install-grammar 'ask)
                     (y-or-n-p (format "\
Tree-sitter grammar for `%s' is missing; install it?"
                                       lang))))
        (treesit-install-language-grammar lang)
        (treesit-ready-p lang))))

(unless (boundp 'treesit-major-mode-remap-alist)
  (defvar treesit-major-mode-remap-alist nil))

(defcustom treesit-enabled-modes nil
  "Specify what treesit modes to enable by default."
  :type '(choice (const :tag "Disable all automatic associations" nil)
                 (const :tag "Enable all available ts-modes" t)
                 (set :tag "List of enabled ts-modes"
                      ,@(when (treesit-available-p)
                          (let ((items (mapcar (lambda (m) `(function-item ,m))
                                               (seq-uniq (mapcar #'cdr treesit-major-mode-remap-alist)))))
                            (sort items #'string<)))))
  :initialize #'custom-initialize-default
  :set (lambda (sym val)
         (set-default sym val)
         (when (treesit-available-p)
           (dolist (m treesit-major-mode-remap-alist)
             (setq major-mode-remap-alist
                   (if (or (eq val t) (memq (cdr m) val))
                       (cons m major-mode-remap-alist)
                     (delete m major-mode-remap-alist))))))
  :version "31.1"
  :group 'treesit)

(defvar +tree-sitter--commit-field? nil)

(setq treesit-auto-install-grammar 'ask
      treesit-enabled-modes t)

(defun tree-sitter! ()
  "Old tree-sitter.el support is deprecated."
  (message "Old tree-sitter.el support is deprecated!"))

(defun set-tree-sitter! (modes ts-mode &optional recipes)
  "Remap major MODES to TS-MODE.

MODES and TS-MODE are major mode symbols.  MODES can be a list thereof.  If
RECIPES is provided, fall back to MODES if RECIPES don't pass `treesit-ready-p'
when activating TS-MODE."
  (declare (indent 2))
  (cl-check-type modes (or list symbol))
  (cl-check-type ts-mode symbol)
  (let ((recipes (mapcar #'ensure-list (ensure-list recipes)))
        (modes (ensure-list modes)))
    (when modes
      (put ts-mode 'derived-mode-extra-parents modes))
    (dolist (m (or modes (list nil)))
      (when m
        (setf (alist-get m major-mode-remap-defaults) ts-mode))
      (put ts-mode '+tree-sitter (cons m (mapcar #'car recipes))))
    ;; HACK: Prevent ts-modes clobbering `auto-mode-alist' and/or
    ;;   `interpreter-mode-alist' from their autoloads or when they're first
    ;;   loaded.
    (dolist (hook '("%s" "%s-maybe"))
      (when-let* ((fn (intern-soft (format hook ts-mode))))
        (dolist (var '(auto-mode-alist interpreter-mode-alist))
          (when-let* ((val (symbol-value var))
                      (entry (rassq fn val)))
            (cl-callf2 delete entry val)
            (defer-until! (and (fboundp ts-mode)
                               (not (autoloadp (symbol-function ts-mode))))
              (cl-callf2 delete entry val))))))
    (when-let* ((recipes (cl-delete-if-not #'cdr recipes)))
      (with-eval-after-load 'treesit
        (dolist (recipe (mapcar #'ensure-list recipes))
          (setf (alist-get (car recipe) treesit-language-source-alist)
                (cdr (apply #'+tree-sitter-source recipe))))))))

(defun +tree-sitter-ts-mode-inhibit-side-effects-a (fn &rest args)
  "Suppress changes to `auto-mode-alist' and `interpreter-mode-alist'."
  (let (auto-mode-alist interpreter-mode-alist)
    (apply fn args)))

;; Intercept major-mode remappings so grammars are checked dynamically and
;; `treesit-auto-install-grammar' is respected.
(defadvice! +tree-sitter--maybe-remap-major-mode-a (fn mode)
  :around #'major-mode-remap
  (let ((mode (funcall fn mode)))
    (if-let* ((ts (get mode '+tree-sitter)) ; registered by `set-tree-sitter!'
              (fallback-mode (car ts)))
        (cond ((get mode '+tree-sitter-mode))
              ((not (eval-when-compile (treesit-available-p)))
               (message "Treesit unavailable, falling back to `%S'" fallback-mode)
               (put mode '+tree-sitter-mode fallback-mode))
              ((not (fboundp mode))
               (message "Couldn't find `%S', falling back to `%S'" mode fallback-mode)
               fallback-mode)
              ((and (or (eq treesit-enabled-modes t)
                        (memq fallback-mode treesit-enabled-modes))
                    ;; Lazily load autoloaded grammar entries.
                    (let ((src-fn (symbol-function mode))
                          ;; Silence missing-grammar warnings; log to *Messages*.
                          (warning-suppress-types (cons '(treesit) warning-suppress-types))
                          ;; For ts-modes that clobber these at load time.
                          auto-mode-alist
                          interpreter-mode-alist)
                      (or (not (autoloadp src-fn))
                          (autoload-do-load src-fn mode)))
                    (or (null (cdr ts)) ; no grammars, no problem!
                        (not (fboundp fallback-mode))
                        (if-let* ((grammars
                                   (cl-loop for g in (cdr ts)
                                            unless (treesit-ready-p g 'message)
                                            collect g)))
                            (if (or (eq treesit-auto-install-grammar 'always)
                                    (if (eq treesit-auto-install-grammar 'ask)
                                        (and (not non-essential)
                                             (y-or-n-p
                                              (format "Missing tree-sitter grammars: %s\nInstall now?"
                                                      (mapconcat #'symbol-name grammars ", "))))))
                                (mapc #'treesit-install-language-grammar grammars)
                              (message "Treesit grammars missing (%s), falling back to `%s'..."
                                       (mapconcat #'symbol-name grammars ", ")
                                       fallback-mode)
                              nil)
                          t)))
                 (put mode '+tree-sitter-mode mode))
              (fallback-mode))
      mode)))

;; These built-in ts-modes clobber `auto-mode-alist' / `interpreter-mode-alist'
;; when activated; suppress them (fixed upstream in 31.1).
(dolist (mode '(csharp-ts-mode
                css-ts-mode
                js-ts-mode
                python-ts-mode))
  (advice-add mode :around #'+tree-sitter-ts-mode-inhibit-side-effects-a))

(defun +tree-sitter/doctor ()
  "Test if the current buffer is correctly tree-sitter-enabled."
  (interactive)
  (unless (treesit-available-p)
    (user-error "This Emacs install wasn't built with treesit support!"))
  (unless (treesit-parser-list)
    (user-error "No tree-sitter parsers are active in this buffer; are the grammars properly installed?"))
  (message "Tree-sitter is functioning in this buffer!"))

;;
;;; tools/lookup set-docsets! (used by the docker module)

(defun set-docsets! (modes &rest docsets)
  "Registers a list of DOCSETS for MODES.

MODES can be one major mode, or a list thereof.  DOCSETS can be strings or
vectors of the form [DOCSET FORM]; the first element can be :add or :remove."
  (declare (indent defun))
  (let ((action (if (keywordp (car docsets)) (pop docsets))))
    (dolist (mode (ensure-list modes))
      (let ((hook (intern (format "%s-hook" mode)))
            (fn (intern (format "+lookup-init--%s-%s" (or action "set") mode))))
        (if (null docsets)
            (remove-hook hook fn)
          (fset
           fn (lambda ()
                (make-local-variable 'dash-docs-docsets)
                (unless (memq action '(:add :remove))
                  (setq dash-docs-docset nil))
                (dolist (spec docsets)
                  (cl-destructuring-bind (docset . pred)
                      (cl-typecase spec
                        (string (cons spec nil))
                        (vector (cons (aref spec 0) (aref spec 1)))
                        (otherwise (signal 'wrong-type-arguments (list spec '(vector string)))))
                    (when (or (null pred)
                              (eval pred t))
                      (if (eq action :remove)
                          (setq dash-docs-docsets (delete docset dash-docs-docsets))
                        (cl-pushnew docset dash-docs-docsets)))))))
          (add-hook hook fn 'append))))))

;;

;;; tools/tools.el ends here
