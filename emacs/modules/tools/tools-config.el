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
  "Doom-compat: buffer-local `cl-letf'."
  (declare (indent 1))
  `(cl-letf ,bindings ,@body))

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

(defvar doom-real-buffer-functions nil
  "Doom-compat: list of functions that classify a buffer as \"real\".")

(defun doom-region-beginning () (region-beginning))
(defun doom-region-end () (region-end))

(defun doom-region (&optional beg end)
  "Doom-compat: return the active region's text, or nil."
  (when (doom-region-active-p)
    (buffer-substring-no-properties (or beg (region-beginning))
                                    (or end (region-end)))))

(defun doom-thing-at-point-or-region (&optional thing)
  "Doom-compat: return the active region or THING at point."
  (let ((regionp (doom-region-active-p)))
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
  (ignore-errors (doom-project-root path)))

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
;;; tools/biblio

(after! oc
  (setq org-cite-global-bibliography
        (ensure-list
         (or (bound-and-true-p citar-bibliography)
             (bound-and-true-p bibtex-completion-bibliography)))
        org-cite-export-processors '((latex biblatex) (t csl))
        org-support-shift-select t)
  (require 'oc-biblatex))

(after! org (require 'oc-csl))

(leaf biblio
  :ensure t
  :defer t)

(leaf citar
  :ensure t
  :defer t
  :init
  (setq org-cite-insert-processor 'citar
        org-cite-follow-processor 'citar
        org-cite-activate-processor 'citar)
  :config
  (when (modulep! :completion vertico +icons)
    (defvar citar-indicator-files-icons
      (citar-indicator-create
       :symbol (nerd-icons-faicon
                "nf-fa-file_o"
                :face 'nerd-icons-green
                :v-adjust -0.1)
       :function #'citar-has-files
       :padding "  "
       :tag "has:files"))
    (defvar citar-indicator-links-icons
      (citar-indicator-create
       :symbol (nerd-icons-faicon
                "nf-fa-link"
                :face 'nerd-icons-orange
                :v-adjust 0.01)
       :function #'citar-has-links
       :padding "  "
       :tag "has:links"))
    (defvar citar-indicator-notes-icons
      (citar-indicator-create
       :symbol (nerd-icons-codicon
                "nf-cod-note"
                :face 'nerd-icons-blue
                :v-adjust -0.3)
       :function #'citar-has-notes
       :padding "    "
       :tag "has:notes"))
    (defvar citar-indicator-cited-icons
      (citar-indicator-create
       :symbol (nerd-icons-faicon
                "nf-fa-circle_o"
                :face 'nerd-icon-green)
       :function #'citar-is-cited
       :padding "  "
       :tag "is:cited"))
    (setq citar-indicators
          (list citar-indicator-files-icons
                citar-indicator-links-icons
                citar-indicator-notes-icons
                citar-indicator-cited-icons))))

(leaf citar-embark
  :ensure t
  :after (citar embark)
  :defer t
  :config
  (citar-embark-mode))

(leaf embark
  :ensure t
  :demand t
  :config
  (setq prefix-help-command #'embark-prefix-help-command)
  (global-set-key (kbd "C-.") #'embark-act))

(leaf embark-consult
  :ensure t
  :after (embark consult)
  :demand t)

;; citar-org-roam: only for `:lang org +roam', not ported.  Dropped.

;;
;;; tools/docker

(leaf docker
  :ensure t
  :defer t)

(leaf dockerfile-mode
  :ensure t
  :defer t
  :mode "Dockerfile\\'")

(after! dockerfile-mode
  (set-docsets! 'dockerfile-mode "Docker")
  (set-formatter! 'dockfmt '("dockfmt" "fmt" filepath) :modes '(dockerfile-mode))
  (when (modulep! :tools docker +lsp)
    (add-hook 'dockerfile-mode-local-vars-hook #'lsp! 'append)))

(leaf dockerfile-ts-mode
  :ensure nil
  :when (modulep! :tools docker +tree-sitter)
  :defer t
  :init
  (set-tree-sitter! 'dockerfile-mode 'dockerfile-ts-mode 'dockerfile))

;;
;;; tools/editorconfig

(leaf editorconfig
  :ensure t
  :demand t
  :config
  (editorconfig-mode 1)
  ;; The elisp implementation is the default (rather than the external
  ;; editorconfig binary).
  (setq editorconfig-get-properties-function #'editorconfig-get-properties)

  (when (modulep! :editor whitespace +trim)
    (setq editorconfig-trim-whitespaces-mode 'ws-butler-mode))

  ;; Archives don't need editorconfig settings (office formats are zipped XML).
  (add-to-list 'editorconfig-exclude-regexps
               "\\.\\(zip\\|\\(doc\\|xls\\|ppt\\)x\\)\\'")

  (defun +editorconfig-disable-indent-detection-h (props)
    "Inhibit `dtrt-indent' if an explicit indent_style and indent_size is
specified by editorconfig."
    (when (and (modulep! :editor whitespace +guess)
               (boundp '+whitespace-guess-inhibit)
               (not +whitespace-guess-inhibit)
               (or (gethash 'indent_style props)
                   (gethash 'indent_size props)))
      (setq +whitespace-guess-inhibit 'editorconfig)))
  (defun +editorconfig-unset-tab-width-in-org-mode-h (props)
    "A tab-width != 8 is an error state in org-mode, so prevent changing it."
    (when (and (gethash 'indent_size props)
               (derived-mode-p 'org-mode))
      (unless (fboundp 'org--set-tab-width)
        (setq tab-width 8))))
  (add-hook 'editorconfig-after-apply-functions #'+editorconfig-disable-indent-detection-h)
  (add-hook 'editorconfig-after-apply-functions #'+editorconfig-unset-tab-width-in-org-mode-h))

;;
;;; tools/eval

(defgroup +eval nil
  "Tools and commands for evaluating code universally and managing REPLs."
  :group 'tools)

(defcustom +eval-handler-functions
  '(+eval-with-repl-fn
    +eval-with-mode-handler-fn
    +eval-with-quickrun-fn)
  "A list of functions to execute when evaluating a region/buffer.
Stops at the first function to return non-nil."
  :type 'hook
  :group '+eval)

(defcustom +eval-popup-min-lines 4
  "The output height threshold (inclusive) before output is displayed in a
popup buffer rather than an overlay on the line at point."
  :type 'integer
  :group '+eval)

(setq eval-expression-print-length nil
      eval-expression-print-level  nil)

(global-set-key [remap eval-region] #'+eval/region)
(global-set-key [remap eval-buffer] #'+eval/buffer)

(defvar +eval-repl-handler-alist nil
  "An alist mapping major modes to plists that describe REPLs.")

(defun set-repl-handler! (modes command &rest plist)
  "Defines a REPL for MODES."
  (declare (indent defun))
  (dolist (mode (ensure-list modes))
    (setf (alist-get mode +eval-repl-handler-alist)
          (cons command plist))))

(defvar +eval-handler-alist nil
  "Alist mapping major modes to interactive runner functions.")

(defun set-eval-handler! (modes command)
  "Define a code evaluator for major mode MODES with `quickrun'."
  (declare (indent defun))
  (dolist (mode (ensure-list modes))
    (cond ((symbolp command)
           (setf (alist-get mode +eval-handler-alist nil t)
                 command))
          ((stringp command)
           (after! quickrun
             (setf (alist-get mode (if (stringp mode)
                                       quickrun-file-alist
                                     quickrun--major-mode-alist)
                              nil t)
                   command)))
          ((listp command)
           (after! quickrun
             (quickrun-add-command
               (or (alist-get mode quickrun--major-mode-alist)
                   (string-remove-suffix "-mode" (symbol-name mode)))
               command :mode mode))))))

(defvar +eval-repl-buffers (make-hash-table :test 'equal)
  "The buffer of the last open repl.")

(defvar +eval-repl-plist nil)

(defun +eval-current-repl-buffer (&optional mode)
  "Return the last active REPL buffer associated with this major mode."
  (when-let* ((project-root (doom-project-root))
              (key (cons (or mode major-mode) project-root))
              (buffer (gethash key +eval-repl-buffers)))
    (and (bufferp buffer)
         (buffer-live-p buffer)
         (buffer-local-value '+eval-repl-plist buffer)
         buffer)))

(defun +eval-repl-select (prompt)
  "Prompt the user to select a REPL."
  (let* ((knowns
          (mapcar
           (lambda (spec)
             (unless (fboundp (car spec))
               (error "Given string/symbol is not a major mode: %s" (car spec)))
             (list (string-join
                    (split-string
                     (capitalize (string-remove-suffix "-mode" (symbol-name (car spec))))
                     "-")
                    " ")
                   (cadr spec)))
           +eval-repl-handler-alist))
         (founds
          (mapcar
           (lambda (spec)
             (list (string-join (split-string (capitalize (cadr spec)) "-") " ")
                   (car spec)))
           (cl-loop for sym being the symbols
                    for sym-name = (symbol-name sym)
                    if (string-match "^\\(?:\\+\\)?\\([^/]+\\)/open-\\(?:\\(.+\\)-\\)?repl$" sym-name)
                    collect (list sym (match-string-no-properties 1 sym-name)))))
         (repls (cl-delete-duplicates (append knowns founds) :test #'equal)))
    (or (assoc (or (completing-read (or prompt "Open a REPL for: ")
                                    (mapcar #'car repls))
                   (user-error "aborting"))
               repls)
        (error "couldn't find a valid repl for %s" major-mode))))

(defun +eval--repl-open (spec &optional displayfn input)
  "Open a repl via the given DISPLAYFN."
  (maphash (lambda (key buffer)
             (unless (buffer-live-p buffer)
               (remhash key +eval-repl-buffers)))
           +eval-repl-buffers)
  (pcase-let ((`(_ ,fn . ,plist) spec))
    (unless (commandp fn)
      (error "couldn't find a valid REPL handler for %s" major-mode))
    (let* ((project-root (doom-project-root))
           (key (cons major-mode project-root))
           buffer)
      (setq buffer
            (funcall (or displayfn #'get-buffer-create)
                     (if (buffer-live-p buffer)
                         buffer
                       (setq buffer
                             (save-window-excursion
                               (if (commandp fn)
                                   (call-interactively fn)
                                 (funcall fn))))
                       (unless buffer
                         (error "REPL handler %S couldn't open the REPL buffer" fn))
                       (unless (bufferp buffer)
                         (error "REPL handler %S failed to return a buffer" fn))
                       (with-current-buffer buffer
                         (setq-local +eval-repl-plist (append (list :repl t) plist)))
                       (puthash key buffer +eval-repl-buffers)
                       buffer)))
      (when (bufferp buffer)
        (with-current-buffer buffer
          (unless (or (derived-mode-p 'term-mode)
                      (eq (current-local-map) (bound-and-true-p term-raw-map)))
            (goto-char (if (and (derived-mode-p 'comint-mode)
                                (cdr comint-last-prompt))
                           (cdr comint-last-prompt)
                         (point-max))))
          (when (bound-and-true-p evil-local-mode)
            (call-interactively #'evil-append-line))
          (when input
            (insert input))
          t)))))

(defun +eval--repl-sender-for (mode &optional beg end)
  (when-let*
      ((plist (cdr (alist-get mode +eval-repl-handler-alist)))
       (fn (or (plist-get plist (if (and beg end) :send-region :send-buffer))
               (unless (and beg end) (plist-get plist :send-region)))))
    (if (and beg end)
        (lambda () (funcall fn beg end))
      fn)))

(defun +eval-with-repl-fn (beg end &optional type)
  "Evaluate the region between BEG and END (inclusive) in an open REPL."
  (when-let* ((buf (+eval-current-repl-buffer))
              ((get-buffer-window buf)))
    (if-let* ((fn (if (eq type 'buffer)
                      (+eval--repl-sender-for major-mode)
                    (+eval--repl-sender-for major-mode beg end))))
        (funcall fn)
      ;; Manually feed selection line-by-line if this repl has no
      ;; :send-buffer/:send-region properties.
      (let* ((region (buffer-substring-no-properties beg end))
             (region
              (with-temp-buffer
                (save-excursion (insert region))
                (when (> (skip-chars-forward "\n") 0)
                  (delete-region (point-min) (point)))
                (indent-rigidly (point-min) (point-max) (- (current-indentation)))
                (buffer-string))))
        (with-selected-window (get-buffer-window buf)
          (with-current-buffer buf
            (goto-char (point-max))
            (dolist (line (split-string region "\n"))
              (insert line)
              (if (bound-and-true-p evil-local-mode)
                  (dlet (evil-move-cursor-back)
                    (evil-save-state
                      (evil-append-line 1)
                      (call-interactively (doom-lookup-key (kbd "RET")))))
                (call-interactively (doom-lookup-key (kbd "RET"))))))))
      t)))

(defun +eval-with-mode-handler-fn (beg end &optional _type mode)
  "Evaluate the selection/buffer using a mode appropriate handler."
  (when-let* ((fn (alist-get (or mode major-mode) +eval-handler-alist)))
    (funcall fn beg end)))

(defun +eval-with-quickrun-fn (beg end &optional type)
  "Evaluate the region or buffer with `quickrun'."
  (when (require 'quickrun nil t)
    (pcase type
      (`buffer (quickrun))
      (`region (quickrun-region beg end))
      (`replace (quickrun-replace-region beg end)))
    t))

(defun +eval/buffer ()
  "Evaluate the whole buffer and display the output."
  (interactive)
  (run-hook-with-args-until-success
   '+eval-handler-functions (point-min) (point-max) 'buffer))

(defun +eval/region (beg end)
  "Evaluate a region between BEG and END and display the output."
  (interactive "r")
  (run-hook-with-args-until-success
   '+eval-handler-functions beg end 'region))

(defun +eval/line-or-region ()
  "Evaluate the current line or selected region."
  (interactive)
  (if (use-region-p)
      (call-interactively #'+eval/region)
    (+eval/region (pos-bol) (pos-eol))))

(defun +eval/buffer-or-region ()
  "Execute `+eval/region' if a selection is active, otherwise `+eval/buffer'."
  (interactive)
  (call-interactively
   (if (doom-region-active-p)
       #'+eval/region
     #'+eval/buffer)))

(defun +eval/region-and-replace (beg end)
  "Evaluate a region between BEG and END, and replace it with the result."
  (interactive "r")
  (if (not (derived-mode-p 'emacs-lisp-mode))
      (quickrun-replace-region beg end)
    (kill-region beg end)
    (condition-case nil
        (prin1 (eval (read (current-kill 0)))
               (current-buffer))
      (error (message "Invalid expression")
             (insert (current-kill 0))))))

(defun +eval-display-results-in-popup (output &optional _source-buffer)
  "Display OUTPUT in a popup buffer at the bottom of the screen."
  (let ((output-buffer (get-buffer-create "*doom eval*")))
    (with-current-buffer output-buffer
      (setq-local scroll-margin 0)
      (erase-buffer)
      (save-excursion (insert output))
      (if (fboundp '+word-wrap-mode)
          (+word-wrap-mode +1)
        (visual-line-mode +1)))
    (when-let* ((win (display-buffer output-buffer)))
      (fit-window-to-buffer win (/ (frame-height) 2)
                            nil (/ (frame-width) 2)))
    output-buffer))

(defun +eval-display-results-in-overlay (output &optional source-buffer)
  "Display OUTPUT in a floating overlay next to or below the cursor."
  (require 'eros)
  (with-current-buffer (or source-buffer (current-buffer))
    (let* ((this-command #'+eval/buffer-or-region)
           (prefix eros-eval-result-prefix)
           (lines (split-string output "\n"))
           (prefixlen (length prefix))
           (len (+ (apply #'max (mapcar #'length lines))
                   prefixlen))
           (next-line? (or (cdr lines)
                           (< (- (window-width)
                                 (save-excursion (goto-char (line-end-position))
                                                 (- (current-column)
                                                    (window-hscroll))))
                              len)))
           (pad (if next-line?
                    (+ (window-hscroll) prefixlen)
                  0)))
      (dlet (eros-overlays-use-font-lock)
        (eros--make-result-overlay
            (concat (make-string (max 0 (- pad prefixlen)) ?\s)
                    prefix
                    (string-join lines (concat hard-newline (make-string pad ?\s))))
          :where (if next-line?
                     (line-beginning-position 2)
                   (line-end-position))
          :duration eros-eval-result-duration
          :format "%s")))))

(defun +eval-display-results (output &optional source-buffer)
  "Display OUTPUT in an overlay or a popup buffer."
  (funcall (if (or current-prefix-arg
                   (with-temp-buffer
                     (insert output)
                     (or (>= (count-lines (point-min) (point-max))
                             +eval-popup-min-lines)
                         (>= (string-width
                              (buffer-substring (point-min)
                                                (save-excursion
                                                  (goto-char (point-min))
                                                  (line-end-position))))
                             (window-width))))
                   (not (require 'eros nil t)))
               #'+eval-display-results-in-popup
             #'+eval-display-results-in-overlay)
           output source-buffer)
  output)

(defun +eval/open-repl-same-window (&optional spec input)
  "Open (or reopen) the REPL for the current major-mode in this window."
  (interactive
   (list (or (unless current-prefix-arg
               (assq major-mode +eval-repl-handler-alist))
             (+eval-repl-select "Open REPL in this window: "))
         (doom-region)))
  (+eval--repl-open spec #'switch-to-buffer input))

(defun +eval/open-repl-other-window (&optional spec input)
  "Open (or reopen) the REPL for the current major-mode in another window."
  (interactive
   (list (or (unless current-prefix-arg
               (assq major-mode +eval-repl-handler-alist))
             (+eval-repl-select "Open REPL in popup: "))
         (doom-region)))
  (+eval--repl-open spec #'pop-to-buffer input))

(defun +eval/buffer-or-region-in-repl (&optional beg end buffer?)
  "Execute the selected region or whole buffer in the REPL."
  (interactive "rP")
  (unless (+eval-current-repl-buffer)
    (call-interactively #'+eval/open-repl-other-window))
  (let* ((region? (and (not buffer?) (doom-region-active-p)))
         (type (if region? 'region 'buffer))
         (beg (if region? beg (point-min)))
         (end (if region? end (point-max))))
    (+eval-with-repl-fn beg end type)))

(when (modulep! :editor evil)
  (evil-define-operator +eval:region (beg end)
    "Evaluate selection or sends it to the open REPL, if available."
    :move-point nil
    (interactive "<r>")
    (+eval/region beg end))

  (evil-define-operator +eval:replace-region (beg end)
    "Evaluate selection and replace it with its result."
    :move-point nil
    (interactive "<r>")
    (+eval/region-and-replace beg end))

  (evil-define-operator +eval:repl (_beg _end)
    "Open REPL and send the current selection to it."
    :move-point nil
    (interactive "<r>")
    (+eval/open-repl-other-window)))

(leaf quickrun
  :ensure t
  :defer t
  :config
  (setq quickrun-focus-p nil)

  (defadvice! +eval--quickrun-fix-evil-visual-region-a ()
    :override #'quickrun--outputter-replace-region
    (let ((output (buffer-substring-no-properties (point-min) (point-max))))
      (with-current-buffer quickrun--original-buffer
        (cl-destructuring-bind (beg . end)
            (if (bound-and-true-p evil-local-mode)
                (cons evil-visual-beginning evil-visual-end)
              (cons (region-beginning) (region-end)))
          (delete-region beg end)
          (insert output))
        (setq quickrun-option-outputter quickrun--original-outputter))))

  (defun +eval--quickrun-auto-close-a (&rest _)
    "Silently re-create the quickrun popup when re-evaluating."
    (when-let* ((win (get-buffer-window quickrun--buffer-name)))
      (let ((inhibit-message t))
        (quickrun--kill-running-process)
        (message ""))
      (delete-window win)))
  (advice-add #'quickrun :before #'+eval--quickrun-auto-close-a)
  (advice-add #'quickrun-region :before #'+eval--quickrun-auto-close-a)

  (defun +eval-quickrun-shrink-window-h ()
    "Shrink the quickrun output window once code evaluation is complete."
    (when-let* ((win (get-buffer-window quickrun--buffer-name)))
      (with-selected-window win
        (let ((ignore-window-parameters t))
          (shrink-window-if-larger-than-buffer)))))
  (defun +eval-quickrun-scroll-to-bof-h ()
    "Ensures cursor is at beginning of output window when displayed."
    (when-let* ((win (get-buffer-window quickrun--buffer-name)))
      (with-selected-window win
        (goto-char (point-min)))))
  (add-hook 'quickrun-after-run-hook #'+eval-quickrun-shrink-window-h)
  (add-hook 'quickrun-after-run-hook #'+eval-quickrun-scroll-to-bof-h)

  (when (modulep! :tools eval +overlay)
    (defadvice! +eval--show-output-in-overlay-a (fn)
      :filter-return #'quickrun--make-sentinel
      (lambda (process event)
        (funcall fn process event)
        (with-current-buffer quickrun--buffer-name
          (when (> (buffer-size) 0)
            (+eval-display-results
             (string-trim (buffer-string))
             quickrun--original-buffer)))))

    (defadvice! +eval--inhibit-quickrun-popup-a (buf cb)
      :override #'quickrun--pop-to-buffer
      (setq quickrun--original-buffer (current-buffer))
      (save-window-excursion
        (with-current-buffer (pop-to-buffer buf)
          (setq quickrun-option-outputter #'ignore)
          (funcall cb))))

    (advice-add #'quickrun--recenter :override #'ignore)))

(leaf eros
  :ensure t
  :when (modulep! :tools eval +overlay)
  :hook (emacs-lisp-mode . eros-mode))

;;
;;; tools/lookup

(defvar +lookup-provider-url-alist
  (append '(("Doom issues"       "https://github.com/orgs/doomemacs/projects/2/views/30?filterQuery=%s")
            ("Doom discourse"    "https://discourse.doomemacs.org/search?q=%s")
            ("Google"            +lookup--online-backend-google "https://google.com/search?q=%s")
            ("Google images"     "https://www.google.com/images?q=%s")
            ("Google maps"       "https://maps.google.com/maps?q=%s")
            ("Kagi"              "https://kagi.com/search?q=%s")
            ("Project Gutenberg" "http://www.gutenberg.org/ebooks/search/?query=%s")
            ("DuckDuckGo"        +lookup--online-backend-duckduckgo "https://duckduckgo.com/?q=%s")
            ("DevDocs.io"        "https://devdocs.io/#q=%s")
            ("StackOverflow"     "https://stackoverflow.com/search?q=%s")
            ("StackExchange"     "https://stackexchange.com/search?q=%s")
            ("Github"            "https://github.com/search?ref=simplesearch&q=%s")
            ("Youtube"           "https://youtube.com/results?aq=f&oq=&search_query=%s")
            ("Wolfram alpha"     "https://wolframalpha.com/input/?i=%s")
            ("Wikipedia"         "https://wikipedia.org/search-redirect.php?language=en&go=Go&search=%s")
            ("MDN"               "https://developer.mozilla.org/en-US/search?q=%s")
            ("Internet archive"  "https://web.archive.org/web/*/%s")
            ("Sourcegraph"       "https://sourcegraph.com/search?q=context:global+%s&patternType=literal"))
          nil)
  "An alist that maps online resources to search urls or commands.")

(defvar +lookup-open-url-fn #'browse-url
  "Function to use to open search urls.")

(defvar +lookup-definition-functions
  '(+lookup-dictionary-definition-backend-fn
    +lookup-xref-definitions-backend-fn
    +lookup-dumb-jump-backend-fn
    +lookup-project-search-backend-fn
    +lookup-evil-goto-definition-backend-fn)
  "Functions for `+lookup/definition' to try.")

(defvar +lookup-implementations-functions ()
  "Functions for `+lookup/implementations' to try.")

(defvar +lookup-type-definition-functions ()
  "Functions for `+lookup/type-definition' to try.")

(defvar +lookup-references-functions
  '(+lookup-thesaurus-definition-backend-fn
    +lookup-xref-references-backend-fn
    +lookup-project-search-backend-fn)
  "Functions for `+lookup/references' to try.")

(defvar +lookup-documentation-functions
  '(+lookup-online-backend-fn)
  "Functions for `+lookup/documentation' to try.")

(defvar +lookup-file-functions
  '(+lookup-bug-reference-backend-fn
    +lookup-ffap-backend-fn)
  "Functions for `+lookup/file' to try.")

(defvar +lookup-dictionary-prefer-offline (modulep! :tools lookup +offline)
  "If non-nil, look up dictionaries online.")

(defun set-lookup-handlers! (modes &rest plist)
  "Define jump handlers for major or minor MODES.

Handlers are registered in the lookup hook variables for the given MODES.  See
the doom :tools lookup docs for the full PLIST format."
  (declare (indent defun))
  (dolist (mode (ensure-list modes))
    (let ((hook (intern (format "%s-hook" mode)))
          (fn   (intern (format "+lookup--init-%s-handlers-h" mode))))
      (if (null (car plist))
          (progn
            (remove-hook hook fn)
            (unintern fn nil))
        (fset
         fn
         (lambda ()
           (cl-destructuring-bind (&key definition implementations type-definition references documentation file xref-backend async)
               plist
             (cl-mapc #'+lookup--set-handler
                      (list definition
                            implementations
                            type-definition
                            references
                            documentation
                            file
                            xref-backend)
                      (list '+lookup-definition-functions
                            '+lookup-implementations-functions
                            '+lookup-type-definition-functions
                            '+lookup-references-functions
                            '+lookup-documentation-functions
                            '+lookup-file-functions
                            'xref-backend-functions)
                      (make-list 5 async)
                      (make-list 5 (or (eq major-mode mode)
                                       (memq mode (get major-mode 'derived-mode-extra-parents))
                                       (and (boundp mode)
                                            (symbol-value mode))))))))
        (add-hook hook fn)))))

(defun +lookup--set-handler (spec functions-var &optional async enable)
  (when spec
    (cl-destructuring-bind (fn . plist)
        (ensure-list spec)
      (if (not enable)
          (remove-hook functions-var fn 'local)
        (put fn '+lookup-async (or (plist-get plist :async) async))
        (add-hook functions-var fn nil 'local)))))

(defun +lookup--run-handler (handler identifier)
  (if (commandp handler)
      (call-interactively handler)
    (funcall handler identifier)))

(defun +lookup--run-handlers (handler identifier origin)
  (doom-log "Looking up '%s' with '%s'" identifier handler)
  (condition-case-unless-debug e
      (let ((wconf (current-window-configuration))
            (result (condition-case-unless-debug e
                        (+lookup--run-handler handler identifier)
                      (error
                       (doom-log "Lookup handler %S threw an error: %s" handler e)
                       'fail))))
        (cond ((eq result 'fail)
               (set-window-configuration wconf)
               nil)
              ((or (get handler '+lookup-async)
                   (eq result 'deferred)))
              ((or result
                   (null origin)
                   (/= (point-marker) origin))
               (prog1 (point-marker)
                 (set-window-configuration wconf)))))
    ((error user-error)
     (message "Lookup handler %S: %s" handler e)
     nil)))

(defun +lookup--jump-to (prop identifier &optional display-fn arg)
  (let* ((origin (point-marker))
         (handlers
          (plist-get (list :definition '+lookup-definition-functions
                           :implementations '+lookup-implementations-functions
                           :type-definition '+lookup-type-definition-functions
                           :references '+lookup-references-functions
                           :documentation '+lookup-documentation-functions
                           :file '+lookup-file-functions)
                     prop))
         (result
          (if arg
              (if-let
                  (handler
                   (intern-soft
                    (completing-read "Select lookup handler: "
                                     (delete-dups
                                      (remq t (append (symbol-value handlers)
                                                      (default-value handlers))))
                                     nil t)))
                  (+lookup--run-handlers handler identifier origin)
                (user-error "No lookup handler selected"))
            (run-hook-wrapped handlers #'+lookup--run-handlers identifier origin))))
    (unwind-protect
        (when (cond ((null result)
                     (message "No lookup handler could find %S" identifier)
                     nil)
                    ((markerp result)
                     (funcall (or display-fn #'switch-to-buffer)
                              (marker-buffer result))
                     (goto-char result)
                     result)
                    (result))
          (with-current-buffer (marker-buffer origin)
            (when (fboundp 'better-jumper-set-jump)
              (better-jumper-set-jump (marker-position origin))))
          result)
      (set-marker origin nil))))

(autoload 'xref--show-defs "xref")
(defun +lookup--xref-show (fn identifier &optional show-fn)
  (let ((xrefs (funcall fn
                        (xref-find-backend)
                        identifier)))
    (when xrefs
      (let* ((jumped nil)
             (xref-after-jump-hook
              (cons (lambda () (setq jumped t))
                    xref-after-jump-hook)))
        (funcall (or show-fn #'xref--show-defs)
                 (lambda () xrefs)
                 nil)
        (if (cdr xrefs)
            'deferred
          jumped)))))

(defun +lookup-dictionary-definition-backend-fn (identifier)
  "Look up dictionary definition for IDENTIFIER."
  (when (derived-mode-p 'text-mode)
    (+lookup/dictionary-definition identifier)
    'deferred))

(defun +lookup-thesaurus-definition-backend-fn (identifier)
  "Look up synonyms for IDENTIFIER."
  (when (derived-mode-p 'text-mode)
    (+lookup/synonyms identifier)
    'deferred))

(defun +lookup-xref-definitions-backend-fn (identifier)
  "Non-interactive wrapper for `xref-find-definitions'."
  (condition-case _
      (+lookup--xref-show 'xref-backend-definitions identifier #'xref--show-defs)
    (cl-no-applicable-method nil)))

(defun +lookup-xref-references-backend-fn (identifier)
  "Non-interactive wrapper for `xref-find-references'."
  (condition-case _
      (+lookup--xref-show 'xref-backend-references identifier #'xref--show-xrefs)
    (cl-no-applicable-method nil)))

(defun +lookup-dumb-jump-backend-fn (identifier)
  "Look up the symbol at point (or selection) with `dumb-jump'."
  (and (require 'dumb-jump nil t)
       (let ((xref-backend-functions '(dumb-jump-xref-activate))
             (stop-infinite-dumb-jump-recursion t))
         (+lookup-xref-definitions-backend-fn identifier))))

(defun +lookup-project-search-backend-fn (identifier)
  "Conducts a simple project text search for IDENTIFIER."
  (when identifier
    (let ((query (doom-pcre-quote identifier)))
      (ignore-errors
        (when (and (modulep! :completion vertico)
                   (fboundp '+vertico-file-search))
          (+vertico-file-search :query query)
          t)))))

(defun +lookup-evil-goto-definition-backend-fn (_identifier)
  "Use `evil-goto-definition' to conduct a text search in the current buffer."
  (when (fboundp 'evil-goto-definition)
    (ignore-errors
      (cl-destructuring-bind (beg . end)
          (bounds-of-thing-at-point 'symbol)
        (evil-goto-definition)
        (let ((pt (point)))
          (not (and (>= pt beg)
                    (<  pt end))))))))

(defun +lookup-ffap-backend-fn (identifier)
  "Tries to locate the file or URL at point (or in active selection)."
  (let ((initial-buffer (current-buffer))
        (guess
         (cond (identifier)
               ((doom-region-active-p)
                (buffer-substring-no-properties
                 (doom-region-beginning)
                 (doom-region-end)))
               ((if (require 'ffap) (ffap-guesser)))
               ((thing-at-point 'filename t)))))
    (cond ((and (stringp guess)
                (or (file-exists-p guess)
                    (ffap-url-p guess)))
           (find-file-at-point guess))
          ((and (stringp guess)
                (string-match-p "/" guess)
                (when-let* ((dir (locate-dominating-file default-directory guess)))
                  (when (file-in-directory-p dir (doom-project-root))
                    (find-file (expand-file-name guess dir))
                    t))))
          ((and (modulep! :completion vertico)
                (doom-project-p)
                (fboundp '+vertico/consult-fd-or-find))
           (+vertico/consult-fd-or-find (doom-project-root) guess))
          ((find-file-at-point (ffap-prompter guess))))
    (not (eq initial-buffer (current-buffer)))))

(defun +lookup-bug-reference-backend-fn (_identifier)
  "Searches for a bug reference in user/repo#123 or #123 format and opens it."
  (require 'bug-reference)
  (when (fboundp 'bug-reference-try-setup-from-vc)
    (let ((old-bug-reference-mode bug-reference-mode)
          (old-bug-reference-prog-mode bug-reference-prog-mode)
          (bug-reference-url-format bug-reference-url-format)
          (bug-reference-bug-regexp bug-reference-bug-regexp))
      (bug-reference-try-setup-from-vc)
      (unwind-protect
          (let ((bug-reference-mode t)
                (bug-reference-prog-mode nil))
            (catch 'found
              (bug-reference-fontify (line-beginning-position) (line-end-position))
              (dolist (o (overlays-at (point)))
                (when-let* ((url (overlay-get o 'bug-reference-url)))
                  (browse-url url)
                  (throw 'found t)))))
        (bug-reference-unfontify (line-beginning-position) (line-end-position))
        (if (or old-bug-reference-mode
                old-bug-reference-prog-mode)
            (bug-reference-fontify (line-beginning-position) (line-end-position)))))))

(defun +lookup/definition (identifier &optional arg)
  "Jump to the definition of IDENTIFIER (defaults to the symbol at point)."
  (interactive (list (doom-thing-at-point-or-region)
                     current-prefix-arg))
  (cond ((null identifier) (user-error "Nothing under point"))
        ((+lookup--jump-to :definition identifier nil arg))
        ((user-error "Couldn't find the definition of %S" (substring-no-properties identifier)))))

(defun +lookup/implementations (identifier &optional arg)
  "Jump to the implementations of IDENTIFIER (defaults to the symbol at point)."
  (interactive (list (doom-thing-at-point-or-region)
                     current-prefix-arg))
  (cond ((null identifier) (user-error "Nothing under point"))
        ((+lookup--jump-to :implementations identifier nil arg))
        ((user-error "Couldn't find the implementations of %S" (substring-no-properties identifier)))))

(defun +lookup/type-definition (identifier &optional arg)
  "Jump to the type definition of IDENTIFIER (defaults to the symbol at point)."
  (interactive (list (doom-thing-at-point-or-region)
                     current-prefix-arg))
  (cond ((null identifier) (user-error "Nothing under point"))
        ((+lookup--jump-to :type-definition identifier nil arg))
        ((user-error "Couldn't find the definition of %S" (substring-no-properties identifier)))))

(defun +lookup/references (identifier &optional arg)
  "Show a list of usages of IDENTIFIER (defaults to the symbol at point)."
  (interactive (list (doom-thing-at-point-or-region)
                     current-prefix-arg))
  (cond ((null identifier) (user-error "Nothing under point"))
        ((+lookup--jump-to :references identifier nil arg))
        ((user-error "Couldn't find references of %S" (substring-no-properties identifier)))))

(defun +lookup/documentation (identifier &optional arg)
  "Show documentation for IDENTIFIER (defaults to symbol at point or selection)."
  (interactive (list (doom-thing-at-point-or-region)
                     current-prefix-arg))
  (cond ((+lookup--jump-to :documentation identifier #'pop-to-buffer arg))
        ((user-error "Couldn't find documentation for %S" (substring-no-properties identifier)))))

(defun +lookup/file (&optional path)
  "Figure out PATH from whatever is at point and open it."
  (interactive)
  (cond ((and path
              buffer-file-name
              (file-equal-p path buffer-file-name)
              (user-error "Already here")))
        ((+lookup--jump-to :file path))
        ((user-error "Couldn't find any files here"))))

(defun +lookup/dictionary-definition (identifier &optional arg)
  "Look up the definition of the word at point (or selection)."
  (interactive
   (list (or (doom-thing-at-point-or-region 'word)
             (if (equal major-mode 'pdf-view-mode)
                 (car (pdf-view-active-region-text)))
             (read-string "Look up in dictionary: "))
         current-prefix-arg))
  (message "Looking up dictionary definition for %S" identifier)
  (cond ((and +lookup-dictionary-prefer-offline
              (require 'wordnut nil t))
         (unless (executable-find wordnut-cmd)
           (user-error "Couldn't find %S installed on your system"
                       wordnut-cmd))
         (wordnut-search identifier))
        ((require 'define-word nil t)
         (define-word identifier nil arg))
        ((user-error "No dictionary backend is available"))))

(defun +lookup/synonyms (identifier &optional _arg)
  "Look up and insert a synonym for the word at point (or selection)."
  (interactive
   (list (doom-thing-at-point-or-region 'word)
         current-prefix-arg))
  (message "Looking up synonyms for %S" identifier)
  (cond ((and +lookup-dictionary-prefer-offline
              (require 'synosaurus-wordnet nil t))
         (unless (executable-find synosaurus-wordnet--command)
           (user-error "Couldn't find %S installed on your system"
                       synosaurus-wordnet--command))
         (synosaurus-choose-and-replace))
        ((require 'powerthesaurus nil t)
         (powerthesaurus-lookup-word-dwim))
        ((user-error "No thesaurus backend is available"))))

(defvar +lookup--last-provider nil)

(defun +lookup--online-provider (&optional force-p namespace)
  (let ((key (or namespace major-mode)))
    (or (and (not force-p)
             (cdr (assq key +lookup--last-provider)))
        (when-let* ((provider
                     (completing-read
                      "Search on: "
                      (mapcar #'car +lookup-provider-url-alist)
                      nil t)))
          (setf (alist-get key +lookup--last-provider) provider)
          provider))))

(defun +lookup-online-backend-fn (identifier)
  "Open the browser and search for IDENTIFIER online."
  (+lookup/online
   identifier
   (+lookup--online-provider (not current-prefix-arg))))

(defun +lookup/online (query provider)
  "Look up QUERY in the browser using PROVIDER."
  (interactive
   (list (if (use-region-p) (doom-thing-at-point-or-region))
         (+lookup--online-provider current-prefix-arg)))
  (let ((backends (cdr (assoc provider +lookup-provider-url-alist))))
    (unless backends
      (user-error "No available online lookup backend for %S provider"
                  provider))
    (catch 'done
      (dolist (backend backends)
        (cl-check-type backend (or string function))
        (cond ((stringp backend)
               (funcall +lookup-open-url-fn
                        (format backend
                                (url-encode-url
                                 (or query
                                     (read-string (format "Search for (on %s): " provider)
                                                  (thing-at-point 'symbol t)))))))
              ((condition-case-unless-debug e
                   (and (fboundp backend)
                        (funcall backend query))
                 (error
                  (setf (alist-get major-mode +lookup--last-provider nil t) nil)
                  (signal (car e) (cdr e))))
               (throw 'done t)))))))

(defun +lookup/online-select ()
  "Run `+lookup/online', but always prompt for the provider to use."
  (interactive)
  (let ((current-prefix-arg t))
    (call-interactively #'+lookup/online)))

(defun +lookup--online-backend-google (query)
  "Search Google, starting with QUERY, with live autocompletion."
  (cond ((and (bound-and-true-p ivy-mode) (fboundp 'counsel-search))
         (dlet ((ivy-initial-inputs-alist `((t . ,query)))
                (counsel-search-engine 'google))
           (call-interactively #'counsel-search)
           t))
        ((and (bound-and-true-p helm-mode) (require 'helm-net nil t))
         (helm :sources 'helm-source-google-suggest
               :buffer "*helm google*"
               :input query)
         t)))

(defun +lookup--online-backend-duckduckgo (query)
  "Search DuckDuckGo, starting with QUERY, with live autocompletion."
  (cond ((and (bound-and-true-p ivy-mode) (fboundp 'counsel-search))
         (dlet ((ivy-initial-inputs-alist `((t . ,query)))
                (counsel-search-engine 'ddg))
           (call-interactively #'counsel-search)
           t))))

(when (modulep! :editor evil)
  (evil-define-command +lookup:online (query &optional bang)
    "Look up QUERY online."
    (interactive "<a><!>")
    (+lookup/online query (+lookup--online-provider bang 'evil-ex))))

(leaf dumb-jump
  :ensure t
  :bind ("M-g j" . dumb-jump-go)
  :commands dumb-jump-result-follow
  :config
  (setq dumb-jump-default-project (doom-user-dir)
        dumb-jump-prefer-searcher 'rg
        dumb-jump-aggressive nil
        dumb-jump-selector 'popup)
  (when (fboundp 'better-jumper-set-jump)
    (add-hook 'dumb-jump-after-jump-hook #'better-jumper-set-jump)))

(leaf request
  :ensure t
  :defer t)

;; The lookup commands are superior, and will consult xref if there are no
;; better backends available.
(global-set-key [remap xref-find-definitions] #'+lookup/definition)
(global-set-key [remap xref-find-references]  #'+lookup/references)

(after! xref
  (leaf consult-xref
    :ensure t
    :defer t
    :init
    (setq xref-show-xrefs-function       #'consult-xref
          xref-show-definitions-function #'consult-xref)))

;; Dash docset integration (`+docsets') and dictionary packages (`+dictionary')
;; are not enabled; their configs are dropped.

;;
;;; tools/lsp (lsp-mode + lsp-ui; eglot variant not enabled)

(defvar +lsp-defer-shutdown 3
  "If non-nil, defer shutdown of LSP servers for this many seconds after the
last workspace buffer is closed.")

(defvar +lsp--default-read-process-output-max nil)
(defvar +lsp--default-gcmh-high-cons-threshold nil)
(defvar +lsp--optimization-init-p nil)

(define-minor-mode +lsp-optimization-mode
  "Deploys universal GC and IPC optimizations for `lsp-mode' and `eglot'."
  :group 'tools
  :global t
  :init-value nil
  (if (not +lsp-optimization-mode)
      (when +lsp--optimization-init-p
        (setq-default read-process-output-max +lsp--default-read-process-output-max
                      +lsp--optimization-init-p nil)
        (unless (fboundp 'igc-info)
          (setq-default gcmh-high-cons-threshold +lsp--default-gcmh-high-cons-threshold)))
    (unless +lsp--optimization-init-p
      (setq +lsp--default-read-process-output-max (default-value 'read-process-output-max))
      (setq-default read-process-output-max (* 1024 1024))
      (unless (fboundp 'igc-info)
        (setq-default +lsp--default-gcmh-high-cons-threshold (default-value 'gcmh-high-cons-threshold)
                      gcmh-high-cons-threshold (* 2 +lsp--default-gcmh-high-cons-threshold))
        (when (bound-and-true-p gcmh-mode)
          (gcmh-set-high-threshold)))
      (setq +lsp--optimization-init-p t))))

(defvar +lsp-company-backends
  (if (modulep! :editor snippets)
      '(:separate company-capf company-yasnippet)
    'company-capf)
  "The backends to prepend to `company-backends' in `lsp-mode' buffers.")

(defun lsp! ()
  "Dispatch to call the currently used lsp client entrypoint."
  (unless (bound-and-true-p lsp-mode)
    (lsp-deferred)))

(defun +lsp/uninstall-server (dir)
  "Delete a LSP server from `lsp-server-install-dir'."
  (interactive
   (list (read-directory-name "Uninstall LSP server: " lsp-server-install-dir nil t)))
  (unless (file-directory-p dir)
    (user-error "Couldn't find %S directory" dir))
  (delete-directory dir 'recursive)
  (message "Uninstalled %S" (file-name-nondirectory dir)))

(defun +lsp/switch-client (client)
  "Switch to another LSP server."
  (interactive
   (progn
     (require 'lsp-mode)
     (list (completing-read
            "Select server: "
            (or (mapcar #'lsp--client-server-id (lsp--filter-clients (-andfn #'lsp--supports-buffer?
                                                                             #'lsp--server-binary-present?)))
                (user-error "No available LSP clients for %S" major-mode))))))
  (require 'lsp-mode)
  (let* ((client (if (symbolp client) client (intern client)))
         (match (car (lsp--filter-clients (lambda (c) (eq (lsp--client-server-id c) client)))))
         (workspaces (lsp-workspaces)))
    (unless match
      (user-error "Couldn't find an LSP client named %S" client))
    (let ((old-priority (lsp--client-priority match)))
      (setf (lsp--client-priority match) 9999)
      (unwind-protect
          (if workspaces
              (lsp-workspace-restart
               (if (cdr workspaces)
                   (lsp--completing-read "Select server: "
                                         workspaces
                                         'lsp--workspace-print
                                         nil t)
                 (car workspaces)))
            (lsp-mode +1))
        (add-transient-hook! 'lsp-after-initialize-hook
          (setf (lsp--client-priority match) old-priority))))))

(defun +lsp-lookup-definition-handler ()
  "Find definition of the symbol at point using LSP."
  (interactive)
  (when-let* ((loc (lsp-request "textDocument/definition"
                                (lsp--text-document-position-params))))
    (lsp-show-xrefs (lsp--locations-to-xref-items loc) nil nil)
    'deferred))

(defun +lsp-lookup-references-handler (&optional include-declaration)
  "Find project-wide references of the symbol at point using LSP."
  (interactive "P")
  (when-let*
      ((loc (lsp-request "textDocument/references"
                         (append (lsp--text-document-position-params)
                                 (list
                                  :context `(:includeDeclaration
                                             ,(lsp-json-bool include-declaration)))))))
    (lsp-show-xrefs (lsp--locations-to-xref-items loc) nil t)
    'deferred))

(leaf lsp-mode
  :ensure t
  :commands (lsp lsp-deferred lsp-install-server)
  :init
  ;; Don't touch ~/.emacs.d, which could be purged without warning.
  (setq lsp-session-file (doom-profile-cache-dir t "lsp-session")
        lsp-server-install-dir (doom-profile-data-dir t "lsp/"))
  ;; Don't auto-kill LSP server after last workspace buffer is killed.
  (setq lsp-keep-workspace-alive nil)

  ;; Disable expensive/impressive features; make them opt-in.
  (setq lsp-enable-folding nil
        lsp-enable-text-document-color nil)
  (setq lsp-enable-on-type-formatting nil)
  (setq lsp-headerline-breadcrumb-enable nil)

  :config
  (set-debug-var! 'lsp-log-io t 2)

  (setq lsp-intelephense-storage-path (doom-profile-data-dir t "lsp-intelephense/")
        lsp-vetur-global-snippets-dir
        (expand-file-name
         "vetur" (or (bound-and-true-p +snippets-dir)
                     (file-name-concat (doom-user-dir) "snippets/")))
        lsp-xml-jar-file (expand-file-name "org.eclipse.lsp4xml-0.3.0-uber.jar" lsp-server-install-dir)
        lsp-groovy-server-file (expand-file-name "groovy-language-server-all.jar" lsp-server-install-dir))

  (defun +lsp-signature-stop-maybe-h ()
    "Close the displayed `lsp-signature'."
    (when lsp-signature-mode
      (lsp-signature-stop)
      t))
  (add-hook 'doom-escape-hook #'+lsp-signature-stop-maybe-h)

  (set-lookup-handlers! 'lsp-mode
    :definition #'+lsp-lookup-definition-handler
    :references #'+lsp-lookup-references-handler
    :documentation '(lsp-describe-thing-at-point :async t)
    :implementations '(lsp-find-implementation :async t)
    :type-definition #'lsp-find-type-definition)

  ;; terraform module not ported; always drop its client.
  (setq lsp-client-packages (delete 'lsp-terraform lsp-client-packages))

  (defadvice! +lsp--respect-user-defined-checkers-a (fn &rest args)
    :around #'lsp-diagnostics-flycheck-enable
    (if (and (boundp 'flycheck-checker) flycheck-checker)
        (let ((old-checker flycheck-checker))
          (apply fn args)
          (setq-local flycheck-checker old-checker))
      (apply fn args)))

  (add-hook 'lsp-before-initialize-hook #'+lsp-optimization-mode)
  (defun +lsp--disable-optimization-mode-if-no-workspaces-h (_workspace)
    (unless (lsp--session-workspaces lsp--session)
      (+lsp-optimization-mode -1)))
  (add-hook 'lsp-after-uninitialized-functions #'+lsp--disable-optimization-mode-if-no-workspaces-h)

  (defvar +lsp--deferred-shutdown-timer nil)
  ;; Defer server shutdown for a few seconds.
  (defadvice! +lsp-defer-server-shutdown-a (fn &optional restart)
    :around #'lsp--shutdown-workspace
    (if (or lsp-keep-workspace-alive
            restart
            (null +lsp-defer-shutdown)
            (= +lsp-defer-shutdown 0))
        (funcall fn restart)
      (when (timerp +lsp--deferred-shutdown-timer)
        (cancel-timer +lsp--deferred-shutdown-timer))
      (setq +lsp--deferred-shutdown-timer
            (run-at-time
             (if (numberp +lsp-defer-shutdown) +lsp-defer-shutdown 3)
             nil (lambda (workspaces)
                   (dolist (ws workspaces)
                     (or (cl-some #'lsp-buffer-live-p
                                  (lsp--workspace-buffers ws))
                         (with-lsp-workspace ws
                           (let ((lsp-restart 'ignore))
                             (funcall fn))))))
             lsp--buffer-workspaces))))

  (when (modulep! :completion corfu)
    (setq lsp-completion-provider :none)
    (add-hook 'lsp-mode-hook #'lsp-completion-mode)))

(leaf lsp-ui
  :ensure t
  :after lsp-mode
  :hook (lsp-mode . lsp-ui-mode)
  :init
  ;; Change `lsp--auto-configure' to not force `lsp-ui-mode' on us.
  (defadvice! +lsp--use-hook-instead-a (fn &rest args)
    :around #'lsp--auto-configure
    (letf! ((#'lsp-ui-mode #'ignore))
      (apply fn args)))
  :config
  (setq lsp-ui-peek-enable nil
        lsp-ui-doc-max-height 8
        lsp-ui-doc-max-width 72         ; 150 (default) is too wide
        lsp-ui-doc-delay 0.75           ; 0.2 (default) is too naggy
        lsp-ui-doc-show-with-mouse nil  ; don't disappear on mouseover
        lsp-ui-doc-position 'at-point
        lsp-ui-sideline-ignore-duplicate t
        ;; Don't show symbol definitions in the sideline (noisy, and bugs with
        ;; flycheck error display).
        lsp-ui-sideline-show-hover nil
        lsp-ui-sideline-actions-icon lsp-ui-sideline-actions-icon-default)

  (define-key lsp-ui-peek-mode-map "j"   #'lsp-ui-peek--select-next)
  (define-key lsp-ui-peek-mode-map "k"   #'lsp-ui-peek--select-prev)
  (define-key lsp-ui-peek-mode-map (kbd "C-k") #'lsp-ui-peek--select-prev-file)
  (define-key lsp-ui-peek-mode-map (kbd "C-j") #'lsp-ui-peek--select-next-file))

(leaf consult-lsp
  :ensure t
  :defer t
  :after lsp-mode
  :init
  (after! lsp-mode
    (map! :map lsp-mode-map [remap xref-find-apropos] #'consult-lsp-symbols)))

;;
;;; tools/magit (+forge, evil-collection integration)

(defvar +magit-open-windows-in-direction 'right
  "What direction to open new windows from the status buffer.")

(defvar +magit-fringe-size '(13 . 1)
  "Size of the fringe in magit-mode buffers.")

(defvar +magit-auto-revert 'local
  "If non-nil, revert associated buffers after Git operations with side-effects.")

;; Gimp `magit-version' so it doesn't complain in sparse clones.
(defadvice! +magit--ignore-version-a (fn &rest args)
  :around #'magit-version
  (let ((inhibit-message (not (called-interactively-p 'any))))
    (apply fn args)))

(defun +magit-display-buffer-fn (buffer)
  "Display magit buffers sensibly: reuse windows, split below, etc."
  (let ((buffer-mode (buffer-local-value 'major-mode buffer)))
    (display-buffer
     buffer (cond
             ((and (eq buffer-mode 'magit-status-mode)
                   (get-buffer-window buffer))
              '(display-buffer-reuse-window))
             ((or
               (bound-and-true-p git-commit-mode)
               (eq buffer-mode 'magit-process-mode)
               (eq major-mode 'magit-log-select-mode))
              (let ((size (if (eq buffer-mode 'magit-process-mode)
                              0.35
                            0.7)))
                `(display-buffer-below-selected
                  . ((window-height . ,(truncate (* (window-height) size)))))))
             ((or
               (not (derived-mode-p 'magit-mode))
               (and (eq major-mode 'magit-status-mode)
                    (memq buffer-mode
                          '(magit-diff-mode
                            magit-stash-mode)))
               (not (memq buffer-mode
                          '(magit-process-mode
                            magit-revision-mode
                            magit-stash-mode
                            magit-status-mode))))
              '(display-buffer-same-window))
             ('(+magit--display-buffer-in-direction))))))

(defun +magit--display-buffer-in-direction (buffer alist)
  "`display-buffer-alist' handler that opens BUFFER in a direction."
  (let ((direction (or (alist-get 'direction alist)
                       +magit-open-windows-in-direction))
        (origin-window (selected-window)))
    (if-let* ((window (window-in-direction direction)))
        (unless magit-display-buffer-noselect
          (select-window window))
      (if-let* ((window (and (not (one-window-p))
                             (window-in-direction
                              (pcase direction
                                (`right 'left)
                                (`left 'right)
                                ((or `up `above) 'down)
                                ((or `down `below) 'up))))))
        (unless magit-display-buffer-noselect
          (select-window window))
        (let ((window (split-window nil nil direction)))
          (when (and (not magit-display-buffer-noselect)
                     (memq direction '(right down below)))
            (select-window window))
          (display-buffer-record-window 'reuse window buffer)
          (set-window-buffer window buffer)
          (set-window-parameter window 'quit-restore (list 'window 'window origin-window buffer))
          (set-window-prev-buffers window nil))))
    (unless magit-display-buffer-noselect
      (switch-to-buffer buffer t t)
      (selected-window))))

(defvar +magit--stale-p nil)

(defun +magit--revertable-buffer-p (buffer)
  (when (buffer-live-p buffer)
    (pcase +magit-auto-revert
      (`t t)
      (`local
       (not (file-remote-p
             (or (buffer-file-name buffer)
                 (buffer-local-value 'default-directory buffer)))))
      ((pred functionp)
       (funcall +magit-auto-revert buffer)))))

(defun +magit--revert-buffer (buffer)
  (with-current-buffer buffer
    (kill-local-variable '+magit--stale-p)
    (when (magit-auto-revert-repository-buffer-p buffer)
      (save-restriction
        (cl-incf magit-auto-revert-counter)
        (when (bound-and-true-p vc-mode)
          (let ((vc-follow-symlinks t))
            (vc-refresh-state))
          (when (fboundp '+vc-gutter-update-h)
            (+vc-gutter-update-h)))
        (when (and (not (get-buffer-process buffer))
                   (funcall buffer-stale-function t))
          (revert-buffer t t t))
        (force-mode-line-update)))))

(defun +magit-mark-stale-buffers-h ()
  "Revert all visible buffers and mark buried buffers as stale."
  (when +magit-auto-revert
    (let ((visible-buffers (doom-visible-buffers nil t)))
      (dolist (buffer (buffer-list))
        (when (+magit--revertable-buffer-p buffer)
          (if (memq buffer visible-buffers)
              (progn
                (+magit--revert-buffer buffer)
                (cl-callf2 delq buffer visible-buffers))
            (with-current-buffer buffer
              (setq-local +magit--stale-p t))))))))

(defun +magit-revert-buffer-maybe-h ()
  "Update `vc' and `diff-hl' if out of date."
  (when +magit--stale-p
    (+magit--revert-buffer (current-buffer))))

(defun +magit/quit (&optional kill-buffer)
  "Bury the current magit buffer.

If KILL-BUFFER, kill this buffer instead of burying it.  If the buried/killed
magit buffer was the last magit buffer open for this repo, kill all magit
buffers for this repo."
  (interactive "P")
  (let ((topdir (magit-toplevel)))
    (funcall magit-bury-buffer-function kill-buffer)
    (or (cl-find-if (lambda (win)
                      (with-selected-window win
                        (and (derived-mode-p 'magit-mode)
                             (equal magit--default-directory topdir))))
                    (window-list))
        (+magit/quit-all))))

(defun +magit/quit-all ()
  "Kill all magit buffers for the current repository."
  (interactive)
  (mapc #'+magit--kill-buffer (magit-mode-get-buffers))
  (+magit-mark-stale-buffers-h))

(defun +magit--kill-buffer (buf)
  "Kill BUF, waiting for its process to finish if it has one."
  (when (and (bufferp buf) (buffer-live-p buf))
    (let ((process (get-buffer-process buf)))
      (if (not (processp process))
          (kill-buffer buf)
        (with-current-buffer buf
          (if (process-live-p process)
              (run-with-timer 5 nil #'+magit--kill-buffer buf)
            (kill-process process)
            (kill-buffer buf)))))))

(defun +magit/start-code-review (arg)
  (interactive "P")
  (call-interactively
    (if (or arg (not (featurep 'forge)))
        #'code-review-start
      #'code-review-forge-pr-at-point)))

(leaf magit
  :ensure t
  :commands magit-file-delete
  :bind ("C-x g" . magit-status)
  :init
  (setq magit-auto-revert-mode nil)  ; we do this ourselves further down
  :config
  (setq magit-diff-refine-hunk t
        magit-save-repository-buffers nil
        magit-revision-insert-related-refs nil
        ;; Use the full path as the project name to prevent name collisions
        ;; between same-named projects.
        magit-uniquify-buffer-names nil
        magit-git-executable (or (executable-find magit-git-executable) "git"))

  ;; Turn ref links into clickable buttons.
  (add-hook 'magit-process-mode-hook #'goto-address-mode)

  ;; Since the project likely now contains new files, purge the projectile
  ;; cache so `projectile-find-file' et all don't produce an stale file list.
  (defvar +magit--last-hash nil)
  (defun +magit-invalidate-projectile-cache-h ()
    (when (bound-and-true-p projectile-mode)
      (let ((hash (buffer-hash))
            projectile-require-project-root
            projectile-enable-caching
            projectile-verbose)
        (unless (equal +magit--last-hash hash)
          (letf! ((#'recentf-cleanup #'ignore))
            (projectile-invalidate-cache nil))
          (setq-local +magit--last-hash hash)))))
  (add-hook 'magit-refresh-buffer-hook #'+magit-invalidate-projectile-cache-h)

  ;; Use a more efficient strategy to auto-revert buffers whose git state has
  ;; changed.
  (add-hook 'magit-post-refresh-hook #'+magit-mark-stale-buffers-h)
  (add-hook 'doom-switch-buffer-hook #'+magit-revert-buffer-maybe-h)
  (add-hook 'doom-switch-frame-hook #'+magit-mark-stale-buffers-h)

  ;; Prevent sudden window position resets when staging/unstaging hunks.
  (defvar +magit--refreshed-buffer nil)
  (defun +magit--set-window-state-h ()
    (when (doom-region-active-p)
      (setq-local +magit--refreshed-buffer
                  (list (current-buffer) (doom-region-beginning) (window-start)))))
  (add-hook 'magit-pre-refresh-hook #'+magit--set-window-state-h)
  (defun +magit--restore-window-state-h ()
    (cl-destructuring-bind (&optional buf pt beg) +magit--refreshed-buffer
      (when (and buf (eq (current-buffer) buf))
        (goto-char pt)
        (set-window-start nil beg t)
        (kill-local-variable '+magit--refreshed-buffer))))
  (add-hook 'magit-post-refresh-hook #'+magit--restore-window-state-h)

  (setq magit-display-buffer-function #'+magit-display-buffer-fn
        magit-bury-buffer-function #'magit-mode-quit-window)

  ;; The mode-line isn't useful in these popups.
  (when (fboundp 'mode-line-invisible-mode)
    (add-hook 'magit-popup-mode-hook #'mode-line-invisible-mode))

  ;; Line numbers add nothing to magit's buffers.
  (add-hook 'magit-popup-mode-hook #'doom-disable-line-numbers-h)
  (add-hook 'magit-mode-hook #'doom-disable-line-numbers-h)

  ;; Add additional switches that seem common enough.
  (transient-append-suffix 'magit-fetch "-p"
    '("-t" "Fetch all tags" ("-t" "--tags")))
  (transient-append-suffix 'magit-pull "-r"
    '("-a" "Autostash" "--autostash"))

  ;; So magit buffers can be switched to (except for process buffers).
  (defun +magit-buffer-p (buf)
    (let ((mode (buffer-local-value 'major-mode buf)))
      (and (provided-mode-derived-p mode 'magit-mode)
           (not (eq mode 'magit-process-mode)))))
  (add-hook 'doom-real-buffer-functions #'+magit-buffer-p)

  ;; Clean up after magit by killing leftover magit buffers.
  (define-key magit-mode-map "q" #'+magit/quit)
  (define-key magit-mode-map "Q" #'+magit/quit-all)

  (defun +magit-enlargen-fringe-h ()
    "Make fringe larger in magit."
    (and (display-graphic-p)
         (derived-mode-p 'magit-section-mode)
         +magit-fringe-size
         (let ((left  (or (car-safe +magit-fringe-size) +magit-fringe-size))
               (right (or (cdr-safe +magit-fringe-size) +magit-fringe-size)))
           (unless (and (= left  (or left-fringe-width 0))
                        (= right (or right-fringe-width 0)))
             (set-window-fringes nil left right)))))
  (add-hook 'magit-section-mode-hook
            (lambda ()
              (add-hook 'window-configuration-change-hook #'+magit-enlargen-fringe-h nil t)))

  (defun +magit-reveal-point-if-invisible-h ()
    "Reveal the point if in an invisible region."
    (if (derived-mode-p 'org-mode)
        (org-reveal '(4))
      (require 'reveal)
      (reveal-post-command)))
  (add-hook 'magit-diff-visit-file-hook #'+magit-reveal-point-if-invisible-h)

  ;; HACK: See magit/magit#5320: large/long status buffers can change the
  ;;   behavior of motions and TAB in obscure ways.
  (add-hook 'magit-status-mode-hook (lambda () (setq-local long-line-threshold nil))))

(leaf forge
  :ensure t
  :when (modulep! :tools magit +forge)
  :after magit
  :commands forge-create-pullreq forge-create-issue
  :preface
  (setq forge-database-file (doom-profile-data-dir t "forge" "forge-database.sqlite"))
  (setq forge-add-default-bindings (not (modulep! :editor evil +everywhere)))
  :init
  (after! ghub-graphql
    (setq ghub-graphql-message-progress t))
  :config
  (evil-define-key 'normal forge-topic-list-mode-map "q" #'kill-current-buffer)
  (when (not forge-add-default-bindings)
    (define-key magit-mode-map [remap magit-browse-thing] #'forge-browse)
    (define-key magit-remote-section-map [remap magit-browse-thing] #'forge-browse-remote)
    (define-key magit-branch-section-map [remap magit-browse-thing] #'forge-browse-branch)))

(leaf code-review
  :ensure t
  :when (modulep! :tools magit +forge)
  :after magit
  :defer t
  :init
  (after! magit (require 'code-review))
  (setq code-review-db-database-file (doom-profile-data-dir t "code-review" "code-review-db-file.sqlite")
        code-review-log-file (doom-profile-data-dir t "code-review" "code-review-error.log")
        code-review-download-dir (doom-profile-data-dir t "code-review/"))
  :config
  (when (fboundp 'set-evil-initial-state!)
    (set-evil-initial-state! 'code-review-mode 'normal))
  (transient-append-suffix 'magit-merge "d"
    '("y" "Review pull request" +magit/start-code-review))
  ;; forge-dispatch "c u" suffix dropped: its layout varies by forge version
  ;; and transient warns (magit-dispatch "o" not found). +magit/start-code-review
  ;; is reachable from magit-merge above.
  )

;; evil-collection-magit/-magit-section are part of evil-collection (not
;; standalone nixpkgs packages), loaded by evil-collection-init after magit.
(when (modulep! :editor evil +everywhere)
  (leaf evil-collection-magit
    :ensure nil
    :after evil-collection
    :defer t
    :init
    (defvar evil-collection-magit-use-z-for-folds t)
    :config
    ;; q is enough; ESC is way too easy for a vimmer to accidentally press.
    (evil-define-key 'normal magit-status-mode-map [escape] nil)

    (after! code-review
      (evil-define-key 'normal code-review-mode-map
        "r" #'code-review-transient-api
        (kbd "RET") #'code-review-comment-add-or-edit))

    ;; Some extra vim-isms I thought were missing from upstream.
    (evil-define-key '(normal visual) magit-mode-map
      "*"  #'magit-worktree
      "zt" #'evil-scroll-line-to-top
      "zz" #'evil-scroll-line-to-center
      "zb" #'evil-scroll-line-to-bottom
      "g=" #'magit-diff-default-context
      "gi" #'forge-jump-to-issues
      "gm" #'forge-jump-to-pullreqs)

    ;; Fix these keybinds because they are blacklisted.
    (evil-define-key '(normal visual) magit-mode-map
      "q" #'+magit/quit
      "Q" #'+magit/quit-all
      "]" #'magit-section-forward-sibling
      "[" #'magit-section-backward-sibling
      "gr" #'magit-refresh
      "gR" #'magit-refresh-all)
    (evil-define-key '(normal visual) magit-status-mode-map
      "gz" #'magit-refresh)
    (evil-define-key '(normal visual) magit-diff-mode-map
      "gd" #'magit-jump-to-diffstat-or-diff)
    ;; Don't open recursive process buffers.
    (evil-define-key '(normal visual) magit-process-mode-map
      "`" #'ignore)

    ;; A more intuitive behavior for TAB in magit buffers.
    (dolist (map (list magit-status-mode-map
                       magit-stash-mode-map
                       magit-revision-mode-map
                       magit-process-mode-map
                       magit-diff-mode-map))
      (evil-define-key 'normal map (kbd "TAB") #'magit-section-toggle))

    (after! git-rebase
      (dolist (key '(("M-k" . "gk") ("M-j" . "gj")))
        (when-let* ((desc (assoc (car key) evil-collection-magit-rebase-commands-w-descriptions)))
          (setcar desc (cdr key))))
      (evil-define-key evil-collection-magit-state git-rebase-mode-map
        "gj" #'git-rebase-move-line-down
        "gk" #'git-rebase-move-line-up))

    (after! code-review
      (pcase-dolist (`(,states _ ,binding ,fn) evil-collection-magit-mode-map-bindings)
        (evil-collection-define-key states 'code-review-mode-map binding fn))))

  (leaf evil-collection-magit-section
    :ensure nil
    :after evil-collection
    :defer t
    :init
    (defvar evil-collection-magit-section-use-z-for-folds evil-collection-magit-use-z-for-folds)
    :config
    (defadvice! +magit--override-evil-collection-defaults-a (&rest _)
      :after #'evil-collection-magit-section-setup
      ;; These numbered keys mask the numerical prefix keys; they've been
      ;; replaced with z1, z2, z3, etc (and 0 with g=).
      (dolist (key '("M-1" "M-2" "M-3" "M-4" "1" "2" "3" "4" "0"))
        (define-key magit-section-mode-map (kbd key) nil)))))

(leaf git-commit
  :ensure t
  :defer t
  :init
  ;; Enforce git commit conventions.
  ;; See https://chris.beams.io/posts/git-commit/
  (setq git-commit-summary-max-length 50
        git-commit-style-convention-checks '(overlong-summary-line non-empty-second-line))
  :config
  (global-git-commit-mode 1)
  (add-hook 'git-commit-mode-hook #'yas-minor-mode)
  (add-hook 'git-commit-mode-hook (lambda () (setq-local fill-column 72)))

  (defun +vc-start-in-insert-state-maybe-h ()
    "Start git-commit-mode in insert state if in a blank commit message."
    (when (and (bound-and-true-p evil-local-mode)
               (not (evil-emacs-state-p))
               (bobp) (eolp))
      (evil-insert-state)))
  (add-hook 'git-commit-setup-hook #'+vc-start-in-insert-state-maybe-h))

;;
;;; tools/pass

(defvar +pass-user-fields '("login" "user" "username" "email")
  "A list of fields for `+pass/ivy' to search for the username.")

(defvar +pass-url-fields '("url" "site" "location")
  "A list of fields for `+pass/ivy' to search for the username.")

(setq password-store-password-length 12)

(defun +pass--copy-username (entry)
  (if-let* ((user (+pass-get-field entry +pass-user-fields)))
      (progn (password-store-clear)
             (message "Copied username to the kill ring.")
             (kill-new user))
    (error "Username not found.")))

(defalias '+pass-get-entry #'auth-source-pass-parse-entry)

(defun +pass-get-field (entry fields &optional noerror)
  "Fetches the value of a field.  FIELDS can be a list of string field names or
a single one.  If a list, the first field found will be returned."
  (if-let* ((data (if (listp entry) entry (+pass-get-entry entry))))
      (cl-loop for key in (ensure-list fields)
               when (assoc key data)
               return (cdr it))
    (unless noerror
      (error "Couldn't find entry: %s" entry))))

(defun +pass-get-user (entry)
  "Fetches the user field from ENTRY."
  (+pass-get-field entry +pass-user-fields))

(defun +pass-get-secret (entry)
  "Fetches your secret from ENTRY."
  (+pass-get-field entry 'secret))

(define-obsolete-function-alias '+pass/edit-entry #'password-store-edit "21.12")
(define-obsolete-function-alias '+pass/copy-field #'password-store-copy-field "21.12")
(define-obsolete-function-alias '+pass/copy-secret #'password-store-copy "21.12")
(define-obsolete-function-alias '+pass/browse-url #'password-store-url "21.12")

(defun +pass/copy-user (entry)
  "Interactively search for an entry and copy the login to your clipboard."
  (interactive
   (list (password-store--completing-read)))
  (+pass--copy-username entry))

(defun +pass/consult (arg pass)
  "Complete and act on password store entries with consult."
  (interactive
   (list current-prefix-arg
         (progn
           (require 'consult)
           (consult--read (password-store-list)
                          :prompt "Pass: "
                          :sort nil
                          :require-match t
                          :category 'pass))))
  (funcall (if arg
               #'password-store-url
             #'password-store-copy)
           pass))

(leaf password-store
  :ensure t
  :bind ("C-c p" . password-store-copy))

(leaf pass
  :ensure t
  :defer t
  :config
  (when (fboundp 'set-evil-initial-state!)
    (set-evil-initial-state! 'pass-mode 'normal))
  (evil-define-key 'normal pass-mode-map
    "j"   #'pass-next-entry
    "k"   #'pass-prev-entry
    "d"   #'pass-kill
    (kbd "C-j") #'pass-next-directory
    (kbd "C-k") #'pass-prev-directory))

(leaf password-store-otp
  :ensure t
  :defer t
  :after password-store)

(after! evil-collection-pass
  (add-to-list 'evil-collection-pass-command-to-label '(pass-update-buffer . "gr")))

;; `+auth' flag not enabled; `auth-source-pass-enable' dropped.

;;
;;; tools/pdf

(leaf pdf-tools
  :ensure t
  :defer t
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :magic ("%PDF" . pdf-view-mode)
  :init
  (after! pdf-annot
    (defun +pdf-cleanup-windows-h ()
      "Kill left-over annotation buffers when the document is killed."
      (when (buffer-live-p pdf-annot-list-document-buffer)
        (pdf-info-close pdf-annot-list-document-buffer))
      (when (buffer-live-p pdf-annot-list-buffer)
        (kill-buffer pdf-annot-list-buffer))
      (let ((contents-buffer (get-buffer "*Contents*")))
        (when (and contents-buffer (buffer-live-p contents-buffer))
          (kill-buffer contents-buffer))))
    (add-hook 'pdf-view-mode-hook
              (lambda ()
                (add-hook 'kill-buffer-hook #'+pdf-cleanup-windows-h nil t))))
  :config
  ;; Install epdfinfo after the first PDF file, if needed.
  (defadvice! +pdf--install-epdfinfo-a (fn &rest args)
    :around #'pdf-view-mode
    (if (and (require 'pdf-info nil t)
             (or (pdf-info-running-p)
                 (ignore-errors (pdf-info-check-epdfinfo) t)))
        (apply fn args)
      (fundamental-mode)
      (message "Viewing PDFs in Emacs requires epdfinfo. Use `M-x pdf-tools-install' to build it")))

  ;; Unlike `pdf-tools-install', this only sets up hooks/alists/global modes
  ;; and never builds the epdfinfo binary (which can block Emacs with compiler
  ;; output).  The advice above degrades gracefully if it's missing.
  (pdf-tools-install-noverify)

  (map! :map pdf-view-mode-map :gn "q" #'kill-current-buffer)

  (setq-default pdf-view-display-size 'fit-page)
  ;; Enable hiDPI support, but at the cost of memory! See politza/pdf-tools#51.
  (setq pdf-view-use-scaling t
        pdf-view-use-imagemagick nil)

  ;; The mode-line doesn't serve any useful purpose in annotation windows.
  (when (fboundp 'mode-line-invisible-mode)
    (add-hook 'pdf-annot-list-mode-hook #'mode-line-invisible-mode))
  (add-hook 'pdf-annot-list-mode-hook #'doom-disable-line-numbers-h)

  ;; HACK: Fix doomemacs/core#1107: flickering pdfs when evil-mode is enabled.
  ;;   We need (list nil) as a workaround for emacs-evil/evil#2016.
  (add-hook 'pdf-view-mode-hook (lambda () (setq-local evil-normal-state-cursor (list nil))))

  ;; Refresh FG/BG for pdfs when `pdf-view-midnight-colors' is changed.
  (defun +pdf-reload-midnight-minor-mode-h ()
    (when pdf-view-midnight-minor-mode
      (pdf-info-setoptions
       :render/foreground (car pdf-view-midnight-colors)
       :render/background (cdr pdf-view-midnight-colors)
       :render/usecolors t)
      (pdf-cache-clear-images)
      (pdf-view-redisplay t)))
  (put 'pdf-view-midnight-colors 'custom-set
       (lambda (sym value)
         (set-default sym value)
         (dolist (buffer (doom-buffers-in-mode 'pdf-view-mode))
           (with-current-buffer buffer
             (if (get-buffer-window buffer)
                 (+pdf-reload-midnight-minor-mode-h)
               (add-hook 'doom-switch-buffer-hook #'+pdf-reload-midnight-minor-mode-h
                         nil 'local))))))

  ;; Silence "File *.pdf is large (X MiB), really open?" prompts for pdfs.
  (defadvice! +pdf-suppress-large-file-prompts-a (fn size op-type filename &optional offer-raw)
    :around #'abort-if-file-too-large
    (unless (string-match-p "\\.pdf\\'" filename)
      (funcall fn size op-type filename offer-raw))))

(leaf saveplace-pdf-view
  :ensure t
  :defer t
  :after pdf-view)

;; org-pdftools needs `:lang org' (not enabled in this config); dropped.

;;
;;; tools/tree-sitter

;; Doom builds on the builtin `treesit'; the recipe list below is its grammar
;; source alist (pins chosen for the ABI shipped with Emacs 30).
(leaf treesit
  :ensure nil
  :when (treesit-available-p)
  :defer t
  :config
  (setq +tree-sitter--commit-field?
        (eq (cdr (func-arity
                  (advice--cd*r
                   (advice--symbol-function 'treesit--install-language-grammar-1))))
            'many))

  ;; Keep $EMACSDIR clean by installing grammars to a central location.
  (let ((data-dir (doom-profile-data-dir t "tree-sitter")))
    (add-to-list 'treesit-extra-load-path data-dir)
    ;; Treesit's API saw major changes in 30.x.  (`treesit--build-grammar' only
    ;; exists in 31+, so only `treesit-install-language-grammar' is advised.)
    (defadvice! +tree-sitter--install-grammar-to-local-dir-a (fn lang &optional out-dir &rest args)
      :around #'treesit-install-language-grammar
      (apply fn lang (or out-dir data-dir) args)))

  (cl-defun +tree-sitter-source (name &key url rev source-dir cc cpp commit)
    (cons name
          (append (list url rev source-dir cc cpp)
                  (if +tree-sitter--commit-field?
                      (list commit)))))

  (dolist (map `(;; Module-less (or major-mode-less) grammars
                 (awk :url "https://github.com/Beaglefoot/tree-sitter-awk")
                 (bibtex :url "https://github.com/latex-lsp/tree-sitter-bibtex")
                 (blueprint :url "https://github.com/huanie/tree-sitter-blueprint")
                 (commonlisp :url "https://github.com/tree-sitter-grammars/tree-sitter-commonlisp")
                 (latex :url "https://github.com/latex-lsp/tree-sitter-latex"
                        :commit "a6c812704b3d3e1541b0853aa0d6d561301320e1")
                 (make :url "https://github.com/tree-sitter-grammars/tree-sitter-make")
                 (nu :url "https://github.com/nushell/tree-sitter-nu")
                 (org :url "https://github.com/milisims/tree-sitter-org")
                 (perl :url "https://github.com/ganezdragon/tree-sitter-perl")
                 (proto :url "https://github.com/mitchellh/tree-sitter-proto")
                 (r :url "https://github.com/r-lib/tree-sitter-r")
                 (sql :url "https://github.com/DerekStride/tree-sitter-sql" :rev "gh-pages")
                 (surface :url "https://github.com/connorlay/tree-sitter-surface")
                 (toml :url "https://github.com/tree-sitter-grammars/tree-sitter-toml"
                       :rev "v0.7.0")
                 (typst :url "https://github.com/uben0/tree-sitter-typst"
                        :rev "master"
                        :source-dir "src")
                 (systemverilog :url "https://github.com/gmlarumbe/tree-sitter-systemverilog")
                 (vhdl :url "https://github.com/alemuller/tree-sitter-vhdl")
                 (vue :url "https://github.com/tree-sitter-grammars/tree-sitter-vue")
                 (wast :url "https://github.com/wasm-lsp/tree-sitter-wasm"
                       :source-dir "wast/src")
                 (wat :url "https://github.com/wasm-lsp/tree-sitter-wasm"
                      :source-dir "wat/src")
                 (wgsl :url "https://github.com/mehmetoguzderin/tree-sitter-wgsl")

                 ;; Grammars with modules
                 (ada :url "https://github.com/briot/tree-sitter-ada")
                 (c :url "https://github.com/tree-sitter/tree-sitter-c"
                    :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.6" "v0.24.1"))
                 (cpp :url "https://github.com/tree-sitter/tree-sitter-cpp"
                      :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.4")
                      :commit "80f5bd82d3b4a1acf07f34a569d88a4a29f74c42")
                 (cmake :url "https://github.com/uyha/tree-sitter-cmake")
                 (c-sharp :url "https://github.com/tree-sitter/tree-sitter-c-sharp"
                          :rev ,(if (< (treesit-library-abi-version) 15) "v0.20.0" "v0.23.1")
                          :commit "3431444351c871dffb32654f1299a00019280f2f")
                 (clojure :url "https://github.com/sogaiu/tree-sitter-clojure")
                 (cuda :url "https://github.com/tree-sitter-grammars/tree-sitter-cuda")
                 (css :url "https://github.com/tree-sitter/tree-sitter-css"
                      :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.0" "v0.23.2"))
                 (dart :url "https://github.com/ast-grep/tree-sitter-dart")
                 (dockerfile :url "https://github.com/camdencheek/tree-sitter-dockerfile"
                             :commit "087daa20438a6cc01fa5e6fe6906d77c869d19fe")
                 (doxygen :url "https://github.com/tree-sitter-grammars/tree-sitter-doxygen"
                          :commit "1e28054cb5be80d5febac082706225e42eff14e6")
                 (elixir :url "https://github.com/elixir-lang/tree-sitter-elixir"
                         :commit "d24cecee673c4c770f797bac6f87ae4b6d7ddec5")
                 (erlang :url "https://github.com/WhatsApp/tree-sitter-erlang")
                 (fsharp :url "https://github.com/ionide/tree-sitter-fsharp"
                         :rev ,(if (< (treesit-library-abi-version) 15) "v0.1.0" "v0.2.0")
                         :commit "594c500ecace8618db32dd1144307897277db067")
                 (gdscript :url "https://github.com/PrestonKnopp/tree-sitter-gdscript.git"
                           :rev ,(if (< (treesit-library-abi-version) 15) "v5.0.1" "v6.1.0"))
                 (glsl :url "https://github.com/tree-sitter-grammars/tree-sitter-glsl")
                 (graphql :url "https://github.com/bkegley/tree-sitter-graphql")
                 (go :url "https://github.com/tree-sitter/tree-sitter-go"
                     :rev ,(if (< (treesit-library-abi-version) 15)
                               (if (< emacs-major-version 30) "v0.20.0" "v0.23.4")
                             "v0.25.0"))
                 (gomod :url "https://github.com/camdencheek/tree-sitter-go-mod"
                        :commit "3b01edce2b9ea6766ca19328d1850e456fde3103")
                 (gowork :url "https://github.com/omertuc/tree-sitter-go-work"
                         :commit "949a8a470559543857a62102c84700d291fc984c")
                 (gpr :url "https://github.com/brownts/tree-sitter-gpr")
                 (haskell :url "https://github.com/tree-sitter/tree-sitter-haskell")
                 (heex :url "https://github.com/phoenixframework/tree-sitter-heex"
                       :commit "b5a7cb5f74dc695a9ff5f04919f872ebc7a895e9")
                 (html :url "https://github.com/tree-sitter/tree-sitter-html"
                       :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.0" "v0.23.2"))
                 (janet-simple :url "https://github.com/sogaiu/tree-sitter-janet-simple"
                               :cc ,(if (featurep :system 'windows) "gcc.exe"))
                 (java :url "https://github.com/tree-sitter/tree-sitter-java"
                       :commit "94703d5a6bed02b98e438d7cad1136c01a60ba2c")
                 (javascript :url "https://github.com/tree-sitter/tree-sitter-javascript"
                             :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.0" "v0.25.0"))
                 (jsdoc :url "https://github.com/tree-sitter/tree-sitter-jsdoc"
                        :rev "v0.23.2")
                 (json :url "https://github.com/tree-sitter/tree-sitter-json"
                       :commit "4d770d31f732d50d3ec373865822fbe659e47c75")
                 (julia :url "https://github.com/tree-sitter/tree-sitter-julia")
                 (kotlin :url "https://github.com/fwcd/tree-sitter-kotlin")
                 (lua :url "https://github.com/tree-sitter-grammars/tree-sitter-lua"
                      :rev ,(if (< (treesit-library-abi-version) 15) "v0.3.0")
                      :commit "db16e76558122e834ee214c8dc755b4a3edc82a9")
                 (markdown :url "https://github.com/tree-sitter-grammars/tree-sitter-markdown"
                           :rev ,(if (< (treesit-library-abi-version) 15) "v0.4.1" "v0.5.3")
                           :source-dir "tree-sitter-markdown/src")
                 (markdown-inline :url "https://github.com/tree-sitter-grammars/tree-sitter-markdown"
                                  :rev ,(if (< (treesit-library-abi-version) 15) "v0.4.1" "v0.5.3")
                                  :source-dir "tree-sitter-markdown-inline/src")
                 (nix :url "https://github.com/nix-community/tree-sitter-nix")
                 (odin :url "https://github.com/tree-sitter-grammars/tree-sitter-odin"
                       :rev "v1.3.0")
                 (openscad :url "https://github.com/openscad/tree-sitter-openscad"
                           :rev "v0.7.1")
                 (php :url "https://github.com/tree-sitter/tree-sitter-php"
                      :rev "v0.23.11"
                      :commit ,(if (and (treesit-available-p)
                                        (< (treesit-library-abi-version) 15))
                                   "f7cf7348737d8cff1b13407a0bfedce02ee7b046"
                                 "5b5627faaa290d89eb3d01b9bf47c3bb9e797dea")
                      :source-dir "php/src")
                 (phpdoc :url "https://github.com/claytonrcarter/tree-sitter-phpdoc"
                         :commit "03bb10330704b0b371b044e937d5cc7cd40b4999")
                 (python :url "https://github.com/tree-sitter/tree-sitter-python"
                         :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.6" "v0.25.0"))
                 (ruby :url "https://github.com/tree-sitter/tree-sitter-ruby"
                       :commit "71bd32fb7607035768799732addba884a37a6210")
                 (rust :url "https://github.com/tree-sitter/tree-sitter-rust"
                       :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.2" "v0.24.2"))
                 (scala :url "https://github.com/tree-sitter/tree-sitter-scala")
                 (sml :url "https://github.com/MatthewFluet/tree-sitter-sml"
                      :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.0")
                      :commit "fd4b4955bb998262840ab8119885b3edf20ea75a")
                 (swift :url "https://github.com/alex-pinkus/tree-sitter-swift"
                        :rev "0.7.1-with-generated-files")
                 (typescript :url "https://github.com/tree-sitter/tree-sitter-typescript"
                             :commit "8e13e1db35b941fc57f2bd2dd4628180448c17d5"
                             :source-dir "typescript/src")
                 (tsx :url "https://github.com/tree-sitter/tree-sitter-typescript"
                      :commit "8e13e1db35b941fc57f2bd2dd4628180448c17d5"
                      :source-dir "tsx/src")
                 (qmljs :url "https://github.com/yuja/tree-sitter-qmljs")
                 (yaml :url "https://github.com/tree-sitter-grammars/tree-sitter-yaml"
                       :rev ,(if (< (treesit-library-abi-version) 15) "v0.7.2" "v0.7.0"))
                 (zig :url "https://github.com/tree-sitter-grammars/tree-sitter-zig")))
    (cl-pushnew (apply #'+tree-sitter-source map)
                treesit-language-source-alist
                :key #'car
                :test #'eq)))

;; Old tree-sitter.el ecosystem removed — redundant with builtin treesit
;; (see lang/lang-extra.el remap). set-tree-sitter! helpers above remain
;; available for code that references them.

;;
;;; tools/upload

(leaf ssh-deploy
  :ensure t
  :commands (ssh-deploy-upload-handler
             ssh-deploy-upload-handler-forced
             ssh-deploy-diff-handler
             ssh-deploy-browse-remote-handler
             ssh-deploy-remote-changes-handler)
  :init
  (setq ssh-deploy-revision-folder (file-name-concat doom-cache-dir "ssh-revisions/")
        ssh-deploy-on-explicit-save 1
        ssh-deploy-automatically-detect-remote-changes nil)

  ;; Forward-declare these as safe file/dir-local variables in case files set
  ;; them before ssh-deploy is loaded.
  (dolist (sym '((ssh-deploy-root-local . stringp)
                 (ssh-deploy-root-remote . stringp)
                 (ssh-deploy-script . functionp)
                 (ssh-deploy-on-explicit-save . booleanp)
                 (ssh-deploy-force-on-explicit-save . booleanp)
                 (ssh-deploy-async . booleanp)
                 (ssh-deploy-exclude-list . listp)))
    (put (car sym) 'safe-local-variable (cdr sym)))

  ;; Respect `ssh-deploy-on-explicit-save' if `ssh-deploy-root-remote' has
  ;; changed since the buffer was opened.
  (defun +upload-init-after-save-h ()
    (when (and (bound-and-true-p ssh-deploy-root-remote)
               (require 'ssh-deploy nil t)
               (integerp ssh-deploy-on-explicit-save)
               (> ssh-deploy-on-explicit-save 0))
      (ssh-deploy-upload-handler ssh-deploy-force-on-explicit-save)
      (when (or ssh-deploy-root-remote
                ssh-deploy-root-local)
        (ssh-deploy-line-mode +1))))
  (add-hook 'after-save-hook #'+upload-init-after-save-h)

  ;; Enable ssh-deploy if variables are set, and check for changes on open file.
  (defun +upload-init-find-file-h ()
    (when (and (bound-and-true-p ssh-deploy-root-remote)
               (require 'ssh-deploy nil t))
      (unless ssh-deploy-root-local
        (setq ssh-deploy-root-local (doom-project-root)))
      (when ssh-deploy-automatically-detect-remote-changes
        (ssh-deploy-remote-changes-handler))
      (when (or ssh-deploy-root-remote
                ssh-deploy-root-local)
        (ssh-deploy-line-mode +1))))
  (add-hook 'find-file-hook #'+upload-init-find-file-h))

;;; tools-config.el ends here
(provide 'tools-config)
