;;; lang-config.el --- doom :lang modules, ported  -*- lexical-binding: t; -*-

;; Ported from doom-modules/modules/lang/{emacs-lisp,org,python,rust,go,cc,
;; nix,sh,markdown,json,yaml,javascript,web}.  Doom-only macros with no compat
;; layer (set-docsets!/set-lookup-handlers!/set-repl-handler!/set-ligatures!/...)
;; are dropped.  Hooks are plain `add-hook' and keybindings use `general', since
;; the compat `map!'/`add-hook!' forms don't survive doom's calling conventions
;; (`:localleader', nested `(:prefix ...)' groups, quoted hook symbols).

;;; Shims for doom-core macros the copied helpers rely on.
(defmacro dlet (bindings &rest body)
  "Vanilla stand-in for doom's `dlet' (dynamic let)."
  (declare (indent 1))
  `(let ,bindings ,@body))

(defmacro quiet! (&rest body)
  "Vanilla stand-in for doom's `quiet!'."
  (declare (indent 0))
  `(let ((inhibit-message t)) (message nil) ,@body))

;;; ===================================================================
;;; :lang emacs-lisp
;;; ===================================================================

(defgroup +emacs-lisp nil
  "Enhances support for Emacs Lisp in Emacs."
  :group 'lisp)

(defcustom +emacs-lisp-enable-extra-fontification t
  "If non-nil, highlight special forms, and defined functions and variables."
  :type 'boolean
  :group '+emacs-lisp)

(defcustom +emacs-lisp-outline-regexp "[ \t]*;;;\\(;*\\**\\) [^ \t\n]"
  "Regexp to use for `outline-regexp' in `emacs-lisp-mode'."
  :type 'regexp
  :group '+emacs-lisp)

(defvar +emacs-lisp-linter-warnings
  '(not free-vars noruntime unresolved)
  "The value for `byte-compile-warnings' in non-packages.")

(defvar +emacs-lisp-working-buffer nil
  "What buffer to evaluate elisp from.")

(defun +emacs-lisp-outline-level ()
  "Return outline level for comment at point."
  (if (match-beginning 1)
      (- (match-end 1) (match-beginning 1))
    0))

(leaf elisp-mode
  :ensure nil
  :interpreter ("doomscript" . emacs-lisp-mode)
  :config
  (add-hook 'emacs-lisp-mode-hook
            (lambda () (setq-local tab-width 8
                              outline-regexp +emacs-lisp-outline-regexp
                              outline-level #'+emacs-lisp-outline-level)))
  (advice-add #'calculate-lisp-indent :override #'+emacs-lisp--calculate-lisp-indent-a)
  (add-hook 'emacs-lisp-mode-hook #'outline-minor-mode)
  (add-hook 'lisp-data-mode-hook #'outline-minor-mode)
  (add-hook 'emacs-lisp-mode-hook #'+emacs-lisp-extend-imenu-h)
  (add-hook 'lisp-data-mode-hook #'+emacs-lisp-extend-imenu-h)

  ;; Enhance elisp syntax highlighting with Doom-specific constructs and
  ;; defined symbols.
  (dolist (mode '(emacs-lisp-mode lisp-data-mode lisp-interaction-mode))
    (font-lock-add-keywords
     mode (append `(;; custom Doom cookies
                    ("^;;;###\\(autodef\\|if\\|package\\)[ \n]" (1 font-lock-warning-face t))
                    ;; defun* and defun! blocks in `letf!'
                    ("(\\(defun[!*]\\)\\_>[ \t]*\\(\\(?:\\sw\\|\\s_\\)+\\)?"
                     (1 font-lock-keyword-face)
                     (2 font-lock-function-name-face nil t)))
                  (when +emacs-lisp-enable-extra-fontification
                    `((+emacs-lisp-highlight-vars-and-faces . +emacs-lisp--face))))))

  ;; Fix the load path seen by the elisp byte-compile flymake backend.
  (defun +syntax--fix-elisp-flymake-load-path (orig-fn &rest args)
    (let ((elisp-flymake-byte-compile-load-path
           (append elisp-flymake-byte-compile-load-path load-path)))
      (apply orig-fn args)))
  (advice-add #'elisp-flymake-byte-compile :around #'+syntax--fix-elisp-flymake-load-path)

  (defun +emacs-lisp-append-value-to-eldoc-a (fn sym)
    "Display variable value next to documentation in eldoc."
    (when-let* ((ret (funcall fn sym)))
      (if (boundp sym)
          (concat ret " "
                  (let* ((truncated " [...]")
                         (print-escape-newlines t)
                         (str (symbol-value sym))
                         (str (prin1-to-string str))
                         (limit (- (frame-width) (length ret) (length truncated) 1)))
                    (format (format "%%0.%ds%%s" (max limit 0))
                            (propertize str 'face 'warning)
                            (if (< (length str) limit) "" truncated))))
        ret)))
  (advice-add #'elisp-get-var-docstring :around #'+emacs-lisp-append-value-to-eldoc-a)

  ;; SPC m localleader in elisp buffers
  (general-define-key
   :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
   :states '(normal visual emacs)
   :prefix doom-localleader-key
   "b" '(#'+emacs-lisp/change-working-buffer :wk "Set working buffer")
   "m" '(macrostep-expand :wk "Expand macro"))
  (general-define-key
   :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " d")
   "f" '(#'+emacs-lisp/edebug-instrument-defun-on :wk "debug defun on")
   "F" '(#'+emacs-lisp/edebug-instrument-defun-off :wk "debug defun off"))
  (general-define-key
   :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " e")
   "b" '(eval-buffer :wk "eval buffer")
   "d" '(eval-defun :wk "eval defun")
   "e" '(eval-last-sexp :wk "eval last sexp")
   "r" '(eval-region :wk "eval region")
   "l" '(load-library :wk "load library"))
  (general-define-key
   :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " g")
   "f" '(find-function :wk "find function")
   "v" '(find-variable :wk "find variable")
   "l" '(find-library :wk "find library")))

(leaf highlight-quoted
  :ensure t
  :hook ((emacs-lisp-mode lisp-data-mode) . highlight-quoted-mode))

(leaf macrostep
  :ensure t
  :commands macrostep-expand)

(leaf ielm
  :ensure nil
  :config
  (setq ielm-font-lock-keywords
        (append '(("\\(^\\*\\*\\*[^*]+\\*\\*\\*\\)\\(.*$\\)"
                   (1 font-lock-comment-face)
                   (2 font-lock-constant-face)))
                (cl-loop for (matcher . match-highlights)
                         in (append lisp-el-font-lock-keywords-2
                                    lisp-cl-font-lock-keywords-2)
                         collect
                         `((lambda (limit)
                             (when ,(if (symbolp matcher)
                                        `(,matcher limit)
                                      `(re-search-forward ,matcher limit t))
                               ;; Only highlight matches after the prompt
                               (> (match-beginning 0) (car comint-last-prompt))
                               ;; Make sure we're not in a comment or string
                               (let ((state (syntax-ppss)))
                                 (not (or (nth 3 state)
                                          (nth 4 state))))))
                           ,@match-highlights)))))

(leaf overseer
  :ensure t
  :init
  (autoload 'overseer-test "overseer" nil t)
  (remove-hook 'emacs-lisp-mode-hook #'overseer-enable-mode))

(leaf package-lint
  :ensure t
  :when (modulep! :checkers syntax)
  :config
  (setq package-lint--sane-prefixes
        (concat "\\`\\(?:doom-\\(?:package\\|source\\|module\\)\\)\\|"
                package-lint--sane-prefixes)))

(leaf elisp-demos
  :ensure t
  :init
  (advice-add #'describe-function-1 :after #'elisp-demos-advice-describe-function-1)
  (advice-add #'helpful-update :after #'elisp-demos-advice-helpful-update)
  :config
  (add-to-list 'elisp-demos-user-files (expand-file-name "demos.org" (doom-user-dir)))
  (defun +emacs-lisp--optimize-org-init-a (fn &rest args)
    "Disable unrelated functionality to optimize calls to `org-mode'."
    (dlet ((org-inhibit-startup t)
           (doom-inhibit-local-var-hooks t)
           enable-dir-local-variables
           org-mode-hook)
      (apply fn args)))
  (dolist (target '(elisp-demos--export-json-file
                    elisp-demos--symbols
                    elisp-demos--syntax-highlight))
    (advice-add target :around #'+emacs-lisp--optimize-org-init-a)))

(leaf buttercup
  :ensure t
  :commands buttercup-minor-mode
  :preface
  (defvar buttercup-minor-mode-map (make-sparse-keymap))
  :init
  (unless (boundp 'auto-minor-mode-alist)
    (defvar auto-minor-mode-alist nil))
  (add-to-list 'auto-minor-mode-alist '("/test[/-].+\\.el$" . buttercup-minor-mode))
  :config
  (when (featurep 'evil)
    (add-hook 'buttercup-minor-mode-hook #'evil-normalize-keymaps))
  (general-define-key
   :keymaps 'buttercup-minor-mode-map
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " t")
   "t" '(#'+emacs-lisp/buttercup-run-file :wk "run file")
   "a" '(#'+emacs-lisp/buttercup-run-project :wk "run project")
   "s" '(buttercup-run-at-point :wk "run at point")))

(leaf helpful
  :ensure t
  :commands helpful--read-symbol
  :hook (helpful-mode . visual-line-mode)
  :init
  (setq apropos-do-all t)
  (global-set-key [remap describe-function] #'helpful-callable)
  (global-set-key [remap describe-command]  #'helpful-command)
  (global-set-key [remap describe-variable] #'helpful-variable)
  (global-set-key [remap describe-key]      #'helpful-key)
  (defun doom-use-helpful-a (fn &rest args)
    "Force FN to use helpful instead of the old describe-* commands."
    (cl-letf (((symbol-function 'describe-function) #'helpful-function)
              ((symbol-function 'describe-variable) #'helpful-variable))
      (apply fn args)))
  (after! apropos
    ;; patch apropos buttons to call helpful instead of help
    (dolist (fun-bt '(apropos-function apropos-macro apropos-command))
      (button-type-put
       fun-bt 'action
       (lambda (button)
         (helpful-callable (button-get button 'apropos-symbol)))))
    (dolist (var-bt '(apropos-variable apropos-user-option))
      (button-type-put
       var-bt 'action
       (lambda (button)
         (helpful-variable (button-get button 'apropos-symbol))))))
  :config
  (add-hook 'helpful-mode-hook (lambda () (setq-local tab-width 8)))
  (defun +emacs-lisp--helpful-suppress-sit-for-a (fn &rest args)
    "Suppress the ~1s freeze when `helpful' probes info manuals."
    (cl-letf (((symbol-function 'sit-for) #'ignore))
      (apply fn args)))
  (advice-add #'helpful--in-manual-p :around #'+emacs-lisp--helpful-suppress-sit-for-a)
  (advice-add #'helpful--manual :around #'+emacs-lisp--helpful-suppress-sit-for-a)
  ;; Open help:* links with helpful-* instead of describe-*
  (advice-add #'org-link--open-help :around #'doom-use-helpful-a)
  ;; Keep a record of buffers so our next/previous commands work.
  (advice-add #'helpful--buffer :filter-return #'+emacs-lisp-record-new-buffers-a)
  (general-define-key
   :keymaps 'helpful-mode-map
   :states '(normal motion)
   "o" '(link-hint-open-link :wk "open link")
   "gr" '(helpful-update :wk "refresh")
   "C-o" '(#'+emacs-lisp/helpful-previous :wk "previous")
   "l" '(#'+emacs-lisp/helpful-previous :wk "previous")
   "r" '(#'+emacs-lisp/helpful-next :wk "next")
   [C-i] '(#'+emacs-lisp/helpful-next :wk "next")
   "<" '(#'+emacs-lisp/helpful-previous :wk "previous")
   ">" '(#'+emacs-lisp/helpful-next :wk "next"))
  (general-define-key
   :keymaps 'helpful-mode-map
   "C-c C-b" #'+emacs-lisp/helpful-previous
   "C-c C-f" #'+emacs-lisp/helpful-next))

(leaf let-completion
  :ensure t
  :hook (emacs-lisp-mode . let-completion-mode))

(leaf elisp-def
  :ensure t
  :commands elisp-def)

;;; -- emacs-lisp helpers (autoload/emacs-lisp.el, autoload/helpful.el) -----

(defun +emacs-lisp/change-working-buffer (buffer)
  "Change what buffer elisp is evaluated in."
  (interactive
   (list (read-buffer
          "Set working buffer to: " (list (current-buffer))
          nil nil)))
  (let ((buffer (if buffer (get-buffer buffer))))
    (cond ((or (null buffer)
               (equal buffer (current-buffer)))
           (kill-local-variable '+emacs-lisp-working-buffer)
           (message "Unset working buffer"))
          ((and buffer (buffer-live-p buffer))
           (setq-local +emacs-lisp-working-buffer buffer)
           (message "Working buffer set to %S" buffer))
          ((user-error "No such buffer: %S" buffer)))))

(defun +emacs-lisp/open-repl ()
  "Open the Emacs Lisp REPL (`ielm')."
  (interactive)
  (pop-to-buffer
   (or (get-buffer "*ielm*")
       (let ((original-buffer (current-buffer)))
         (ielm)
         (when (buffer-live-p original-buffer)
           (ielm-change-working-buffer original-buffer))
         (let ((buf (get-buffer "*ielm*")))
           (bury-buffer buf)
           buf)))))

(defun +emacs-lisp/edebug-instrument-defun-on ()
  "Toggle on instrumenting the function under `defun'."
  (interactive)
  (eval-defun 'edebugit))

(defun +emacs-lisp/edebug-instrument-defun-off ()
  "Toggle off instrumenting the function under `defun'."
  (interactive)
  (eval-defun nil))

(defun +emacs-lisp-lookup-definition (_thing)
  "Lookup the definition of THING."
  (call-interactively #'elisp-def))

(defun +emacs-lisp-lookup-documentation (thing)
  "Lookup documentation of THING with helpful."
  (if thing
      (helpful-symbol (intern thing))
    (call-interactively #'helpful-at-point)))

(defun +emacs-lisp/buttercup-run-file ()
  "Run all buttercup tests in the focused buffer."
  (interactive)
  (let ((load-path
         (append (list default-directory (or (doom-project-root)
                                             default-directory))
                 load-path))
        (buttercup-suites nil))
    (save-selected-window
      (eval-buffer)
      (buttercup-run))
    (message "File executed successfully")))

(defun +emacs-lisp/buttercup-run-project ()
  "Run all buttercup tests in the project."
  (interactive)
  (let ((default-directory (doom-project-root)))
    (let ((load-path (append (list (expand-file-name "test" default-directory)
                                   default-directory)
                             load-path))
          (buttercup-suites nil))
      (buttercup-run-discover))))

(defun +emacs-lisp-extend-imenu-h ()
  "Improve imenu support in `emacs-lisp-mode' for Doom's APIs."
  (setq imenu-generic-expression
        `(("Evil commands" "^\\s-*(evil-define-\\(?:command\\|operator\\|motion\\) +\\(\\_<[^ ()\n]+\\_>\\)" 1)
          ("Unit tests" "^\\s-*(\\(?:ert-deftest\\|describe\\) +\"\\([^\")]+\\)\"" 1)
          ("Package" "^\\s-*\\(?:;;;###package\\|(\\(?:package!\\|use-package!?\\|after!\\)\\) +\\(\\_<[^ ()\n]+\\_>\\)" 1)
          ("Major modes" "^\\s-*(define-derived-mode +\\([^ ()\n]+\\)" 1)
          ("Minor modes" "^\\s-*(define-\\(?:global\\(?:ized\\)?-minor\\|generic\\|minor\\)-mode +\\([^ ()\n]+\\)" 1)
          ("Modelines" "^\\s-*(def-modeline! +\\([^ ()\n]+\\)" 1)
          ("Modeline segments" "^\\s-*(def-modeline-segment! +\\([^ ()\n]+\\)" 1)
          ("Advice" "^\\s-*(\\(?:def\\(?:\\(?:ine-\\)?advice!?\\)\\) +\\([^ )\n]+\\)" 1)
          ("Macros" "^\\s-*(\\(?:cl-\\)?def\\(?:ine-compile-macro\\|macro\\) +\\([^ )\n]+\\)" 1)
          ("Inline functions" "\\s-*(\\(?:cl-\\)?defsubst +\\([^ )\n]+\\)" 1)
          ("CLI Command" "^\\s-*(\\(def\\(?:cli\\|alias\\|obsolete\\|autoload\\)! +\\([^\n]+\\)\\)" 1)
          ("Functions" "^\\s-*(\\(?:cl-\\)?def\\(?:un\\|un\\*\\|method\\|generic\\|-memoized!\\) +\\([^ ,)\n]+\\)" 1)
          ("Variables" "^\\s-*(\\(def\\(?:c\\(?:onst\\(?:ant\\)?\\|ustom\\)\\|ine-symbol-macro\\|parameter\\|var\\(?:-local\\)?\\)\\)\\s-+\\(\\(?:\\sw\\|\\s_\\|\\\\.\\)+\\)" 2)
          ("Types" "^\\s-*(\\(cl-def\\(?:struct\\|type\\)\\|def\\(?:class\\|face\\|group\\|ine-\\(?:condition\\|error\\|widget\\)\\|package\\|struct\\|t\\(?:\\(?:hem\\|yp\\)e\\)\\)\\)\\s-+'?(?\\(\\(?:\\sw\\|\\s_\\|\\\\.\\)+\\)" 2)
          ("Section" "^[ \t]*;;;+\\**[ \t]+\\([^\n]+\\)" 1))))

(defvar +emacs-lisp--face nil)
(defun +emacs-lisp-highlight-vars-and-faces (end)
  "Match defined variables and functions."
  (catch 'matcher
    (while (re-search-forward "\\(?:\\sw\\|\\s_\\)+" end t)
      (let ((ppss (save-excursion (syntax-ppss))))
        (cond ((nth 3 ppss)  ; strings
               (search-forward "\"" end t))
              ((nth 4 ppss)  ; comments
               (forward-line +1))
              ((let ((symbol (intern-soft (match-string-no-properties 0))))
                 (and (cond ((null symbol) nil)
                            ((eq symbol t) nil)
                            ((keywordp symbol) nil)
                            ((special-variable-p symbol)
                             (setq +emacs-lisp--face 'font-lock-variable-name-face))
                            ((and (fboundp symbol)
                                  (eq (char-before (match-beginning 0)) ?\()
                                  (not (memq (char-before (1- (match-beginning 0)))
                                             (list ?\' ?\`))))
                             (let ((unaliased (indirect-function symbol)))
                               (unless (or (macrop unaliased)
                                           (special-form-p unaliased))
                                 (let (unadvised)
                                   (while (not (eq (setq unadvised (ad-get-orig-definition unaliased))
                                                   (setq unaliased (indirect-function unadvised)))))
                                   unaliased)
                                 (setq +emacs-lisp--face
                                       (if (subrp unaliased)
                                           'font-lock-constant-face
                                         'font-lock-function-name-face))))))
                      (throw 'matcher t)))))))
    nil))

(defun +emacs-lisp--calculate-lisp-indent-a (&optional parse-start)
  "Add better indentation for quoted and backquoted lists.
Intended as :override advice for `calculate-lisp-indent'."
  (defvar calculate-lisp-indent-last-sexp)
  (save-excursion
    (beginning-of-line)
    (let ((indent-point (point))
          state
          (desired-indent nil)
          (retry t)
          calculate-lisp-indent-last-sexp containing-sexp)
      (cond ((or (markerp parse-start) (integerp parse-start))
             (goto-char parse-start))
            ((null parse-start)
             (beginning-of-defun))
            ((setq state parse-start)))
      (unless state
        (while (< (point) indent-point)
          (setq state (parse-partial-sexp (point) indent-point 0))))
      (while (and retry
                  state
                  (> (elt state 0) 0))
        (setq retry nil)
        (setq calculate-lisp-indent-last-sexp (elt state 2))
        (setq containing-sexp (elt state 1))
        (goto-char (1+ containing-sexp))
        (if (and calculate-lisp-indent-last-sexp
                 (> calculate-lisp-indent-last-sexp (point)))
            (let ((peek (parse-partial-sexp calculate-lisp-indent-last-sexp
                                            indent-point 0)))
              (if (setq retry (car (cdr peek))) (setq state peek)))))
      (if retry
          nil
        (goto-char (1+ containing-sexp))
        (if (not calculate-lisp-indent-last-sexp)
            (setq desired-indent (current-column))
          (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
          (cond ((looking-at "\\s(")
                 )
                ((> (save-excursion (forward-line 1) (point))
                    calculate-lisp-indent-last-sexp)
                 (if (or
                      (= (point) calculate-lisp-indent-last-sexp)
                      (or
                       ;; Align keywords in plists if each newline begins with
                       ;; a keyword.
                       (when-let* ((first (elt state 1))
                                   (char (char-after (1+ first))))
                         (and (eq char ?:)
                              (ignore-errors
                                (or (save-excursion
                                      (goto-char first)
                                      (when-let* ((parse-sexp-ignore-comments t)
                                                  (end (scan-lists (point) 1 0))
                                                  (depth (ppss-depth (syntax-ppss))))
                                        (and (re-search-forward "^\\s-*:" end t)
                                             (= (ppss-depth (syntax-ppss))
                                                (1+ depth)))))
                                    (save-excursion
                                      (cl-loop for pos in (reverse (elt state 9))
                                               unless (memq (char-after (1+ pos)) '(?: ?\())
                                               do (goto-char (1+ pos))
                                               for fn = (read (current-buffer))
                                               if (symbolp fn)
                                               return (function-get fn 'indent-plists-as-data)))))))
                       ;; Check for quotes or backquotes around.
                       (let ((positions (elt state 9))
                             (quotep 0))
                         (while positions
                           (let ((point (pop positions)))
                             (or (when-let* ((char (char-before point)))
                                   (cond
                                    ((eq char ?\())
                                    ((memq char '(?\' ?\`))
                                     (or (save-excursion
                                           (goto-char (1+ point))
                                           (skip-chars-forward "( ")
                                           (when-let* ((fn (ignore-errors (read (current-buffer)))))
                                             (if (and (symbolp fn)
                                                      (fboundp fn)
                                                      (not (functionp fn)))
                                                 (setq quotep 0))))
                                         (cl-incf quotep)))
                                    ((memq char '(?, ?@))
                                     (setq quotep 0))))
                                 (save-excursion
                                   (goto-char (1+ point))
                                   (and (looking-at-p "\\(\\(?:back\\)?quote\\)[\t\n\f\s]+(")
                                        (cl-incf quotep 2)))
                                 (setq quotep (max 0 (1- quotep))))))
                         (> quotep 0))))
                     nil
                   (progn (forward-sexp 1)
                          (parse-partial-sexp (point)
                                              calculate-lisp-indent-last-sexp
                                              0 t)))
                 (backward-prefix-chars))
                (t
                 (goto-char calculate-lisp-indent-last-sexp)
                 (beginning-of-line)
                 (parse-partial-sexp (point) calculate-lisp-indent-last-sexp
                                     0 t)
                 (backward-prefix-chars)))))
      (let ((normal-indent (current-column)))
        (cond ((elt state 3)
               nil)
              ((and (integerp lisp-indent-offset) containing-sexp)
               (goto-char containing-sexp)
               (+ (current-column) lisp-indent-offset))
              (calculate-lisp-indent-last-sexp
               (or
                (and lisp-indent-function
                     (not retry)
                     (funcall lisp-indent-function indent-point state))
                (and (save-excursion
                       (goto-char indent-point)
                       (skip-chars-forward " \t")
                       (looking-at ":"))
                     (save-excursion
                       (goto-char calculate-lisp-indent-last-sexp)
                       (backward-prefix-chars)
                       (while (not (or (looking-back "^[ \t]*\\|([ \t]+"
                                                     (line-beginning-position))
                                       (and containing-sexp
                                            (>= (1+ containing-sexp) (point)))))
                         (forward-sexp -1)
                         (backward-prefix-chars))
                       (setq calculate-lisp-indent-last-sexp (point)))
                     (> calculate-lisp-indent-last-sexp
                        (save-excursion
                          (goto-char (1+ containing-sexp))
                          (parse-partial-sexp (point) calculate-lisp-indent-last-sexp 0 t)
                          (point)))
                     (let ((parse-sexp-ignore-comments t)
                           indent)
                       (goto-char calculate-lisp-indent-last-sexp)
                       (or (and (looking-at ":")
                                (setq indent (current-column)))
                           (and (< (line-beginning-position)
                                   (prog2 (backward-sexp) (point)))
                                (looking-at ":")
                                (setq indent (current-column))))
                       indent))
                normal-indent))
              (desired-indent)
              (normal-indent))))))

(defvar +emacs-lisp--helpful-buffer-ring-size 5
  "How many buffers are stored for use with `+emacs-lisp/helpful-next'.")

(defvar +emacs-lisp--helpful-buffer-ring (make-ring +emacs-lisp--helpful-buffer-ring-size)
  "Ring that stores the current Helpful buffer history.")

(defun +emacs-lisp--helpful-buffer-index (&optional buffer)
  "If BUFFER is a Helpful buffer, return its index in the buffer ring."
  (let ((buf (or buffer (current-buffer))))
    (and (eq (buffer-local-value 'major-mode buf) 'helpful-mode)
         (seq-position (ring-elements +emacs-lisp--helpful-buffer-ring) buf #'eq))))

(defun +emacs-lisp-record-new-buffers-a (buf)
  "Update the buffer ring according to the current buffer and BUFFER."
  (let ((buf-ring +emacs-lisp--helpful-buffer-ring))
    (let ((newer-buffers (or (+emacs-lisp--helpful-buffer-index) 0)))
      (dotimes (_ newer-buffers) (ring-remove buf-ring 0)))
    (when (/= (ring-size buf-ring) +emacs-lisp--helpful-buffer-ring-size)
      (ring-resize buf-ring +emacs-lisp--helpful-buffer-ring-size))
    (ring-insert buf-ring buf)))

(defun +emacs-lisp--helpful-next (&optional buffer)
  "Return the next live Helpful buffer relative to BUFFER."
  (let ((buf-ring +emacs-lisp--helpful-buffer-ring)
        (index (or (+emacs-lisp--helpful-buffer-index buffer) -1)))
    (cl-block nil
      (while (> index 0)
        (cl-decf index)
        (let ((buf (ring-ref buf-ring index)))
          (if (buffer-live-p buf) (cl-return buf)))
        (ring-remove buf-ring index)))))

(defun +emacs-lisp--helpful-previous (&optional buffer)
  "Return the previous live Helpful buffer relative to BUFFER."
  (let ((buf-ring +emacs-lisp--helpful-buffer-ring)
        (index (1+ (or (+emacs-lisp--helpful-buffer-index buffer) -1))))
    (cl-block nil
      (while (< index (ring-length buf-ring))
        (let ((buf (ring-ref buf-ring index)))
          (if (buffer-live-p buf) (cl-return buf)))
        (ring-remove buf-ring index)))))

(defun +emacs-lisp/helpful-next ()
  "Go to the next Helpful buffer."
  (interactive)
  (if-let* ((buf (+emacs-lisp--helpful-next)))
      (funcall helpful-switch-buffer-function buf)
    (user-error "No helpful buffer to switch to")))

(defun +emacs-lisp/helpful-previous ()
  "Go to the previous Helpful buffer."
  (interactive)
  (if-let* ((buf (+emacs-lisp--helpful-previous)))
      (funcall helpful-switch-buffer-function buf)
    (user-error "No helpful buffer to switch to")))
;;; ===================================================================
;;; :lang org  (biggest module)
;;; ===================================================================

(defvar +org-babel-native-async-langs '(python)
  "Languages that will use `ob-comint' instead of `ob-async' for `:async'.")

(defvar +org-babel-mode-alist
  '((c . C)
    (cpp . C)
    (C++ . C)
    (D . C)
    (elisp . emacs-lisp)
    (sh . shell)
    (bash . shell)
    (matlab . octave)
    (rust . rustic-babel)
    (amm . ammonite))
  "An alist mapping languages to babel libraries. This is necessary for babel
libraries (ob-*.el) that don't match the name of the language.")

(defvar +org-babel-load-functions ()
  "A list of functions executed to load the current executing src block.")

(defvar +org-capture-todo-file "todo.org"
  "Default target for todo entries.
Is relative to `org-directory', unless it is absolute. Is used in the default
`org-capture-templates'.")

(defvar +org-capture-changelog-file "changelog.org"
  "Default target for changelog entries.
Is relative to `org-directory' unless it is absolute.")

(defvar +org-capture-notes-file "notes.org"
  "Default target for storing notes.
Is relative to `org-directory', unless it is absolute.")

(defvar +org-capture-journal-file "journal.org"
  "Default target for storing timestamped journal entries.")

(defvar +org-capture-projects-file "projects.org"
  "Default, centralized target for org-capture templates.")

(defvar +org-habit-graph-padding 2
  "The padding added to the end of the consistency graph.")

(defvar +org-habit-min-width 30
  "Hide the consistency graph if `org-habit-graph-column' is less than this.")

(defvar +org-habit-graph-window-ratio 0.3
  "The ratio of the consistency graphs relative to the window width.")

(defvar +org-preview-dir (expand-file-name "org/previews/" (doom-profile-cache-dir))
  "Where link preview images are cached.")

(defvar +org-startup-with-animated-gifs nil
  "If non-nil, and the cursor is over a gif inline-image preview, animate it.")

;;; -- org-load hooks (config.el) -------------------------------------------

(defun +org-init-org-directory-h ()
  (unless org-directory
    (setq-default org-directory "~/org"))
  (unless org-id-locations-file
    (setq org-id-locations-file (expand-file-name ".orgids" org-directory))))

(defun +org-init-agenda-h ()
  (unless org-agenda-files
    (setq-default org-agenda-files (list org-directory)))
  (setq-default
   ;; Different colors for different priority levels
   org-agenda-deadline-faces
   '((1.001 . error)
     (1.0 . org-warning)
     (0.5 . org-upcoming-deadline)
     (0.0 . org-upcoming-distant-deadline))
   ;; Don't monopolize the whole frame just for the agenda
   org-agenda-window-setup 'current-window
   org-agenda-skip-unavailable-files t
   ;; Shift the agenda to show the previous 3 days and the next 7 days for
   ;; better context on your week.
   org-agenda-span 10
   org-agenda-start-on-weekday nil
   org-agenda-start-day "-3d"
   ;; Optimize `org-agenda' by inhibiting extra work while opening agenda
   ;; buffers in the background.
   org-agenda-inhibit-startup t))

(defun +org-init-appearance-h ()
  "Configures the UI for `org-mode'."
  (setq org-indirect-buffer-display 'current-window
        org-enforce-todo-dependencies t
        org-entities-user
        '(("flat"  "\\flat" nil "" "" "266D" "♭")
          ("sharp" "\\sharp" nil "" "" "266F" "♯"))
        org-fontify-done-headline t
        org-fontify-quote-and-verse-blocks t
        org-fontify-whole-heading-line t
        org-hide-leading-stars t
        org-image-actual-width nil
        org-imenu-depth 6
        org-priority-faces
        '((?A . error)
          (?B . warning)
          (?C . shadow))
        org-startup-indented t
        org-tags-column 0
        org-use-sub-superscripts '{}
        org-startup-folded nil)

  (setq org-refile-targets
        '((nil :maxlevel . 3)
          (org-agenda-files :maxlevel . 3))
        org-refile-use-outline-path 'file
        org-outline-path-complete-in-steps nil)

  (plist-put org-format-latex-options :scale 1.5) ; larger previews

  (with-no-warnings
    (custom-declare-face '+org-todo-active  '((t (:inherit (bold font-lock-constant-face org-todo)))) "")
    (custom-declare-face '+org-todo-project '((t (:inherit (bold font-lock-doc-face org-todo)))) "")
    (custom-declare-face '+org-todo-onhold  '((t (:inherit (bold warning org-todo)))) "")
    (custom-declare-face '+org-todo-cancel  '((t (:inherit (bold error org-todo)))) ""))
  (setq org-todo-keywords
        '((sequence
           "TODO(t)"  ; A task that needs doing & is ready to do
           "PROJ(p)"  ; A project, which usually contains other tasks
           "LOOP(r)"  ; A recurring task
           "STRT(s)"  ; A task that is in progress
           "WAIT(w)"  ; Something external is holding up this task
           "HOLD(h)"  ; This task is paused/on hold because of me
           "IDEA(i)"  ; An unconfirmed and unapproved task or notion
           "|"
           "DONE(d)"  ; Task successfully completed
           "KILL(k)") ; Task was cancelled, aborted, or is no longer applicable
          (sequence
           "[ ](T)"   ; A task that needs doing
           "[-](S)"   ; Task is in progress
           "[?](W)"   ; Task is being held up or paused
           "|"
           "[X](D)")  ; Task was completed
          (sequence
           "|"
           "OKAY(o)"
           "YES(y)"
           "NO(n)"))
        org-todo-keyword-faces
        '(("[-]"  . +org-todo-active)
          ("STRT" . +org-todo-active)
          ("[?]"  . +org-todo-onhold)
          ("WAIT" . +org-todo-onhold)
          ("HOLD" . +org-todo-onhold)
          ("PROJ" . +org-todo-project)
          ("NO"   . +org-todo-cancel)
          ("KILL" . +org-todo-cancel))))

(defun +org-init-babel-h ()
  (setq org-src-preserve-indentation t  ; use native major-mode indentation
        org-src-tab-acts-natively t
        org-confirm-babel-evaluate nil
        org-link-elisp-confirm-function nil
        ;; Show src buffer in other window, and don't monopolize the frame
        org-src-window-setup 'other-window)

  ;; A shorter alias for markdown code blocks.
  (add-to-list 'org-src-lang-modes '("md" . markdown))

  ;; I prefer C-c C-c over C-c ' (more consistent)
  (define-key org-src-mode-map (kbd "C-c C-c") #'org-edit-src-exit)

  ;; Don't process babel results asynchronously when exporting org, as they
  ;; won't likely complete in time.
  (after! ob
    (add-to-list 'org-babel-default-lob-header-args '(:sync)))

  (defun +org--exclude-expand-noweb-references-a (fn &rest args)
    "Exclude the noweb expansion cache buffer from ob-async variable injection."
    (dlet ((async-inject-variables-exclude-regexps
            (cons "\\`org-babel-expand-noweb-references--cache-buffer\\'"
                  async-inject-variables-exclude-regexps)))
      (apply fn args)))
  (advice-add #'ob-async-org-babel-execute-src-block :around #'+org--exclude-expand-noweb-references-a)

  (defun +org-babel-disable-async-maybe-a (fn &optional orig-fn arg info params)
    "Use ob-comint where supported, disable async altogether where it isn't."
    (if (null orig-fn)
        (funcall fn orig-fn arg info params)
      (let* ((info (or info (org-babel-get-src-block-info)))
             (params (org-babel-merge-params (nth 2 info) params)))
        (if (or (assq :sync params)
                (not (assq :async params))
                (member (car info) ob-async-no-async-languages-alist)
                (unless (member (alist-get :session params) '("none" nil))
                  (unless (memq (let* ((lang (nth 0 info))
                                       (lang (cond ((symbolp lang) lang)
                                                   ((stringp lang) (intern lang)))))
                                  (or (alist-get lang +org-babel-mode-alist)
                                      lang))
                                +org-babel-native-async-langs)
                    (message "Org babel: %s :session is incompatible with :async. Executing synchronously!"
                             (car info))
                    (sleep-for 0.2))
                  t))
            (funcall orig-fn arg info params)
          (funcall fn orig-fn arg info params)))))
  (advice-add #'ob-async-org-babel-execute-src-block :around #'+org-babel-disable-async-maybe-a)

  (defun +org-inhibit-mode-hooks-a (fn datum name &optional initialize &rest args)
    "Prevent potentially expensive mode hooks in `org-src--edit-element' ops."
    (apply fn datum name
           (if (and (eq org-src-window-setup 'switch-invisibly)
                    (functionp initialize))
               (lambda ()
                 (dlet ((doom-inhibit-local-var-hooks t))
                   (funcall initialize)))
             initialize)
           args))
  (advice-add #'org-src--edit-element :around #'+org-inhibit-mode-hooks-a)

  ;; Refresh inline images after executing src blocks (useful for plantuml,
  ;; where the result could be an image)
  (defun +org-redisplay-inline-images-in-babel-result-h ()
    (unless (or
             ;; ...but not while Emacs is exporting an org buffer (where
             ;; `org-display-inline-images' can be awfully slow).
             (bound-and-true-p org-export-current-backend)
             ;; ...and not while tangling org buffers (which happens in a temp
             ;; buffer where `buffer-file-name' is nil).
             (string-match-p "^ \\*temp" (buffer-name)))
      (save-excursion
        (when-let* ((beg (org-babel-where-is-src-block-result))
                    (end (progn (goto-char beg) (forward-line) (org-babel-result-end))))
          (org-display-inline-images nil nil (min beg end) (max beg end))))))
  (add-hook 'org-babel-after-execute-hook #'+org-redisplay-inline-images-in-babel-result-h))

(defun +org-init-babel-lazy-loader-h ()
  "Load babel libraries lazily when babel blocks are executed."
  (defun +org--babel-lazy-load (lang &optional async)
    (cl-check-type lang (or symbol null))
    ;; ob-async has its own agenda for lazy loading packages (in the child
    ;; process), so we only need to make sure it's loaded.
    (when async
      (require 'ob-async nil t))
    (unless (cdr (assq lang org-babel-load-languages))
      (prog1 (or (run-hook-with-args-until-success '+org-babel-load-functions lang)
                 (require (intern (format "ob-%s" lang)) nil t)
                 (require lang nil t))
        (add-to-list 'org-babel-load-languages (cons lang t)))))

  (defun +org--export-lazy-load-library-h (&optional element)
    "Lazy load a babel package when a block is executed during exporting."
    (let ((info (org-babel-get-src-block-info nil element)))
      (+org--babel-lazy-load-library-a info)))
  (advice-add #'org-babel-exp-src-block :before #'+org--export-lazy-load-library-h)

  (defun +org--src-lazy-load-library-a (lang)
    "Lazy load a babel package to ensure syntax highlighting."
    (or (cdr (assoc lang org-src-lang-modes))
        (+org--babel-lazy-load lang)))
  (advice-add #'org-src--get-lang-mode :before #'+org--src-lazy-load-library-a)

  ;; This also works for tangling
  (defun +org--babel-lazy-load-library-a (info)
    "Load babel libraries lazily when babel blocks are executed."
    (let* ((lang (nth 0 info))
           (lang (cond ((symbolp lang) lang)
                       ((stringp lang) (intern lang))))
           (lang (or (cdr (assq lang +org-babel-mode-alist))
                     lang)))
      (+org--babel-lazy-load
       lang (and (not (assq :sync (nth 2 info)))
                 (assq :async (nth 2 info))))
      t))
  (advice-add #'org-babel-confirm-evaluate :after-while #'+org--babel-lazy-load-library-a)

  (advice-add #'org-babel-do-load-languages :override #'ignore))

(defun +org-init-capture-defaults-h ()
  "Sets up Doom's default `org-capture' templates."
  (setq org-default-notes-file
        (expand-file-name +org-capture-notes-file org-directory)
        +org-capture-journal-file
        (expand-file-name +org-capture-journal-file org-directory)
        org-capture-templates
        '(
          ;; The traditional way: invoking `org-capture' directly.
          ("t" "Personal todo" entry
           (file+headline +org-capture-todo-file "Inbox")
           "* [ ] %?\n%i\n%a" :prepend t)
          ("n" "Personal notes" entry
           (file+headline +org-capture-notes-file "Inbox")
           "* %u %?\n%i\n%a" :prepend t)
          ("j" "Journal" entry
           (file+olp+datetree +org-capture-journal-file)
           "* %U %?\n%i\n%a" :prepend t)

          ;; Will use {project-root}/{todo,notes,changelog}.org, unless a
          ;; {todo,notes,changelog}.org file is found in a parent directory.
          ("p" "Templates for projects")
          ("pt" "Project-local todo" entry  ; {project-root}/todo.org
           (file+headline +org-capture-project-todo-file "Inbox")
           "* TODO %?\n%i\n%a" :prepend t)
          ("pn" "Project-local notes" entry  ; {project-root}/notes.org
           (file+headline +org-capture-project-notes-file "Inbox")
           "* %U %?\n%i\n%a" :prepend t)
          ("pc" "Project-local changelog" entry  ; {project-root}/changelog.org
           (file+headline +org-capture-project-changelog-file "Unreleased")
           "* %U %?\n%i\n%a" :prepend t)

          ;; Will use {org-directory}/projects.org and store these under
          ;; {ProjectName}/{Tasks,Notes,Changelog} headings. They support
          ;; `:parents' to specify what headings to put them under.
          ("o" "Centralized templates for projects")
          ("ot" "Project todo" entry
           (function +org-capture-central-project-todo-file)
           "* TODO %?\n %i\n %a"
           :heading "Tasks"
           :prepend nil)
          ("on" "Project notes" entry
           (function +org-capture-central-project-notes-file)
           "* %U %?\n %i\n %a"
           :heading "Notes"
           :prepend t)
          ("oc" "Project changelog" entry
           (function +org-capture-central-project-changelog-file)
           "* %U %?\n %i\n %a"
           :heading "Changelog"
           :prepend t)))

  ;; Kill capture buffers by default (unless they've been visited)
  (after! org-capture
    (org-capture-put :kill-buffer t))

  ;; Fix doomemacs/core#462: when refiling from org-capture, Emacs prompts to
  ;; kill the underlying, modified buffer. This fixes that.
  (defun +org-save-buffer-after-capture-h ()
    (when (bound-and-true-p org-capture-is-refiling)
      (save-buffer)))
  (add-hook 'org-after-refile-insert-hook #'+org-save-buffer-after-capture-h)

  (defun +org--capture-expand-variable-file-a (args)
    "Filter-args advice on `org-capture-expand-file': expand variable-valued
file targets relative to `org-directory', unless they are absolute paths."
    (let ((file (car args)))
      (if (and (symbolp file) (boundp file))
          (list (expand-file-name (symbol-value file) org-directory))
        args)))
  (advice-add #'org-capture-expand-file :filter-args #'+org--capture-expand-variable-file-a)

  (defun +org-show-target-in-capture-header-h ()
    (setq header-line-format
          (format "%s%s%s"
                  (propertize (abbreviate-file-name (buffer-file-name (buffer-base-buffer)))
                              'face 'font-lock-string-face)
                  org-eldoc-breadcrumb-separator
                  header-line-format)))
  (add-hook 'org-capture-mode-hook #'+org-show-target-in-capture-header-h))

(defun +org-init-capture-frame-h ()
  (add-hook 'org-capture-after-finalize-hook #'+org-capture-cleanup-frame-h)
  (defun +org-capture-refile-cleanup-frame-a (&rest _)
    (+org-capture-cleanup-frame-h))
  (advice-add #'org-capture-refile :after #'+org-capture-refile-cleanup-frame-a))

(defun +org-init-attachments-h ()
  "Sets up org's attachment system."
  (setq org-attach-store-link-p 'attached     ; store link after attaching files
        org-attach-use-inheritance t) ; inherit properties from parent nodes

  (leaf org-attach
    :ensure nil
    :commands (org-attach-delete-one
               org-attach-delete-all
               org-attach-new
               org-attach-open
               org-attach-open-in-emacs
               org-attach-reveal-in-emacs
               org-attach-url
               org-attach-set-directory
               org-attach-sync)
    :config
    (unless org-attach-id-dir
      ;; Centralized attachments directory by default
      (setq-default org-attach-id-dir (expand-file-name ".attach/" org-directory))))

  ;; Add inline image previews for attachment links
  (org-link-set-parameters "attachment" :preview #'+org-link-preview-attachment-fn))

(defun +org-init-custom-links-h ()
  ;; Modify default file: links to colorize broken file links red
  (org-link-set-parameters
   "file" :face (lambda (path)
                  (if (or
                       ;; file uris is not a valid path on windows
                       (if (featurep :system 'windows) (string-prefix-p "//" path))
                       (file-remote-p path)
                       ;; filter out network shares on windows (slow)
                       (if (featurep :system 'windows) (string-prefix-p "\\\\" path))
                       (file-exists-p path))
                      'org-link
                    '(warning org-link))))

  ;; Additional custom links for convenience
  (dolist (abbrev '(("github"     . "https://github.com/%s")
                    ("youtube"    . "https://youtube.com/watch?v=%s")
                    ("google"     . "https://google.com/search?q=")
                    ("gimages"    . "https://google.com/images?q=%s")
                    ("gmap"       . "https://maps.google.com/maps?q=%s")
                    ("kagi"       . "https://kagi.com/search?q=%s")
                    ("duckduckgo" . "https://duckduckgo.com/?q=%s")
                    ("wikipedia"  . "https://en.wikipedia.org/wiki/%s")
                    ("wolfram"    . "https://wolframalpha.com/input/?i=%s")))
    (add-to-list 'org-link-abbrev-alist abbrev))

  (defun +org-dir (tag)
    "Build an (abbreviated) path to TAG under `org-directory'."
    (abbreviate-file-name (expand-file-name tag org-directory)))
  (add-to-list 'org-link-abbrev-alist '("org" . +org-dir))

  ;; Allow inline image previews of http(s)? urls or data uris.
  (setq org-display-remote-inline-images 'download) ; TRAMP urls
  (org-link-set-parameters "http"  :preview #'+org-link-preview-image-url-fn)
  (org-link-set-parameters "https" :preview #'+org-link-preview-image-url-fn)
  (org-link-set-parameters "data"  :preview #'+org-link-preview-image-data-fn))

(defun +org-init-export-h ()
  (setq org-export-with-smart-quotes t
        org-html-validation-link nil
        org-latex-prefer-user-labels t)

  (when (modulep! :lang markdown)
    (add-to-list 'org-export-backends 'md))

  (leaf ox-pandoc
    :ensure t
    :when (modulep! +pandoc)
    :when (executable-find "pandoc")
    :after ox
    :init
    (add-to-list 'org-export-backends 'pandoc)
    (setq org-pandoc-options
          '((standalone . t)
            (mathjax . t)
            (variable . "revealjs-url=https://revealjs.com"))))

  (defun +org--dont-trigger-save-hooks-a (fn &rest args)
    "Exporting and tangling trigger save hooks; suppress them."
    (dlet (before-save-hook after-save-hook)
      (apply fn args)))
  (dolist (fn '(org-export-to-file org-babel-tangle))
    (advice-add fn :around #'+org--dont-trigger-save-hooks-a))

  (defun +org--fix-async-export-a (fn &rest args)
    "Point `org-export-async-init-file' at a generated init file."
    (let ((old-async-init-file org-export-async-init-file)
          (org-export-async-init-file (make-temp-file "doom-org-async-export")))
      (with-temp-file org-export-async-init-file
        (prin1 `((setq org-export-async-debug ,(or org-export-async-debug debug-on-error)
                       load-path ',load-path)
                 (unwind-protect
                     (let ((init-file ,old-async-init-file))
                       (if init-file
                           (load init-file nil t)
                         (load ,early-init-file nil t)))
                   (delete-file load-file-name)))
               (current-buffer))
        (insert "\n"))
      (apply fn args)))
  (dolist (fn '(org-export-to-file org-export-as))
    (advice-add fn :around #'+org--fix-async-export-a)))

(defun +org-init-habit-h ()
  (defun +org-habit-resize-graph-h ()
    "Right align and resize the consistency graphs based on
`+org-habit-graph-window-ratio'"
    (when (featurep 'org-habit)
      (let* ((total-days (float (+ org-habit-preceding-days org-habit-following-days)))
             (preceding-days-ratio (/ org-habit-preceding-days total-days))
             (graph-width (floor (* (window-width) +org-habit-graph-window-ratio)))
             (preceding-days (floor (* graph-width preceding-days-ratio)))
             (following-days (- graph-width preceding-days))
             (graph-column (- (window-width) (+ preceding-days following-days)))
             (graph-column-adjusted (if (> graph-column +org-habit-min-width)
                                        (- graph-column +org-habit-graph-padding)
                                      nil)))
        (setq-local org-habit-preceding-days preceding-days)
        (setq-local org-habit-following-days following-days)
        (setq-local org-habit-graph-column graph-column-adjusted))))
  (add-hook 'org-agenda-mode-hook #'+org-habit-resize-graph-h))

(defun +org-init-hacks-h ()
  "Getting org to behave."
  ;; Open file links in current window, rather than new ones
  (setf (alist-get 'file org-link-frame-setup) #'find-file)
  ;; Open directory links in dired
  (add-to-list 'org-file-apps '(directory . emacs))
  (add-to-list 'org-file-apps '(remote . emacs))

  (defun +org--strip-properties-from-outline-a (fn &rest args)
    "Fix variable height faces in eldoc breadcrumbs."
    (dlet ((org-level-faces
            (cl-loop for face in org-level-faces
                     collect `(:foreground ,(face-foreground face nil t)
                               :weight bold))))
      (apply fn args)))
  (advice-add #'org-format-outline-path :around #'+org--strip-properties-from-outline-a)

  (defun +org--restart-mode-h ()
    "Restart `org-mode', but only once."
    (remove-hook 'doom-switch-buffer-hook #'+org--restart-mode-h 'local)
    (quiet! (org-mode-restart))
    (cl-callf2 delq (current-buffer) org-agenda-new-buffers)
    (run-hooks 'find-file-hook))

  (defun +org-exclude-agenda-buffers-from-workspace-h ()
    "Don't associate temporary agenda buffers with current workspace."
    (when (and org-agenda-new-buffers
               (bound-and-true-p persp-mode)
               (not org-agenda-sticky))
      (dlet (persp-autokill-buffer-on-remove)
        (persp-remove-buffer org-agenda-new-buffers
                             (get-current-persp)
                             nil))))
  (add-hook 'org-agenda-finalize-hook #'+org-exclude-agenda-buffers-from-workspace-h)

  (defun +org--restart-mode-before-indirect-buffer-a (&optional buffer _)
    "Restart `org-mode' in deferred agenda buffers before org-capture uses them."
    (with-current-buffer (or buffer (current-buffer))
      (when (memq #'+org--restart-mode-h doom-switch-buffer-hook)
        (+org--restart-mode-h))))
  (advice-add #'org-capture-get-indirect-buffer :before #'+org--restart-mode-before-indirect-buffer-a)

  (defun +org--optimize-backgrounded-agenda-buffers-a (fn file)
    "Disable `org-mode's startup processes for temporary agenda buffers."
    (if-let* ((buf (org-find-base-buffer-visiting file)))
        buf
      (dlet ((recentf-exclude '(always))
             (doom-inhibit-local-var-hooks t)
             (org-inhibit-startup t)
             so-long-target-modes
             vc-handled-backends
             enable-local-variables
             find-file-hook)
        (when-let* ((buf (delay-mode-hooks (funcall fn file))))
          (with-current-buffer buf
            (add-hook 'doom-switch-buffer-hook #'+org--restart-mode-h
                      nil 'local))
          buf))))
  (advice-add #'org-get-agenda-file-buffer :around #'+org--optimize-backgrounded-agenda-buffers-a)

  (defun +org--fix-inconsistent-uuidgen-case-a (uuid)
    "Ensure uuidgen is always lowercase (consistent) regardless of system."
    (if (eq org-id-method 'uuid)
        (downcase uuid)
      uuid))
  (advice-add #'org-id-new :filter-return #'+org--fix-inconsistent-uuidgen-case-a))
(defun +org-init-keybinds-h ()
  "Sets up org-mode keybindings."
  (add-hook 'doom-escape-hook #'+org-remove-occur-highlights-h)

  ;; C-a & C-e act like the doom bol/eol commands, but with org awareness.
  (setq org-special-ctrl-a/e t)

  (setq org-M-RET-may-split-line nil
        ;; insert new headings after current subtree rather than inside it
        org-insert-heading-respect-content t)

  (add-hook 'org-tab-first-hook #'+org-yas-expand-maybe-h)
  (add-hook 'org-tab-first-hook #'+org-indent-maybe-h)

  ;; Doom's `doom-delete-backward-functions' hook has no vanilla equivalent;
  ;; the +org-delete-backward-char-and-realign-table-maybe-h helper is defined
  ;; below for reference.

  (general-define-key
   :keymaps 'org-mode-map
   "C-c C-S-l"  #'+org/remove-link
   "C-c <C-i>"  #'org-link-preview-refresh
   ;; textmate-esque newline insertion
   "S-RET"      #'+org/shift-return
   "C-RET"      #'+org/insert-item-below
   "C-S-RET"    #'+org/insert-item-above
   "C-M-RET"    #'org-insert-subheading
   [C-return]   #'+org/insert-item-below
   [C-S-return] #'+org/insert-item-above
   [C-M-return] #'org-insert-subheading
   ;; Org-aware C-a/C-e (doom equivalents ported in keybindings-config.el)
   [remap +doom/backward-to-bol-or-indent]          #'org-beginning-of-line
   [remap +doom/forward-to-last-non-comment-or-eol] #'org-end-of-line)

  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual emacs)
   :prefix doom-localleader-key
   "#" '(org-update-statistics-cookies :wk "update statistics cookies")
   "'" '(org-edit-special :wk "edit source")
   "*" '(org-ctrl-c-star :wk "toggle section")
   "-" '(org-ctrl-c-minus :wk "toggle item")
   "," '(org-switchb :wk "switch buffer")
   "." '(consult-org-heading :wk "jump to heading")
   "/" '(consult-org-agenda :wk "jump to heading in agenda files")
   "@" '(org-cite-insert :wk "insert citation")
   "A" '(org-archive-subtree-default :wk "archive subtree")
   "e" '(org-export-dispatch :wk "export")
   "f" '(org-footnote-action :wk "footnote")
   "h" '(org-toggle-heading :wk "toggle heading")
   "i" '(org-toggle-item :wk "toggle item")
   "I" '(org-id-get-create :wk "create id")
   "k" '(org-babel-remove-result :wk "remove babel result")
   "K" '(#'+org/remove-result-blocks :wk "remove result blocks")
   "n" '(org-store-link :wk "store link")
   "o" '(org-set-property :wk "set property")
   "q" '(org-set-tags-command :wk "set tags")
   "t" '(org-todo :wk "todo")
   "T" '(org-todo-list :wk "todo list")
   "x" '(org-toggle-checkbox :wk "toggle checkbox"))

  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " a")
   "a" '(org-attach :wk "attach")
   "d" '(org-attach-delete-one :wk "delete one")
   "D" '(org-attach-delete-all :wk "delete all")
   "f" '(#'+org/find-file-in-attachments :wk "find file in attachments")
   "l" '(#'+org/attach-file-and-insert-link :wk "attach and insert link")
   "n" '(org-attach-new :wk "new attachment")
   "o" '(org-attach-open :wk "open")
   "O" '(org-attach-open-in-emacs :wk "open in emacs")
   "r" '(org-attach-reveal :wk "reveal")
   "R" '(org-attach-reveal-in-emacs :wk "reveal in emacs")
   "u" '(org-attach-url :wk "attach url")
   "s" '(org-attach-set-directory :wk "set directory")
   "S" '(org-attach-sync :wk "sync"))

  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " b")
   "-" '(org-table-insert-hline :wk "insert hline")
   "a" '(org-table-align :wk "align table")
   "b" '(org-table-blank-field :wk "blank field")
   "c" '(org-table-create-or-convert-from-region :wk "create table")
   "e" '(org-table-edit-field :wk "edit field")
   "f" '(org-table-edit-formulas :wk "edit formulas")
   "h" '(org-table-field-info :wk "field info")
   "s" '(org-table-sort-lines :wk "sort lines")
   "r" '(org-table-recalculate :wk "recalculate")
   "R" '(org-table-recalculate-buffer-tables :wk "recalculate buffer")
   "dc" '(org-table-delete-column :wk "delete column")
   "dr" '(org-table-kill-row :wk "kill row")
   "ic" '(org-table-insert-column :wk "insert column")
   "ih" '(org-table-insert-hline :wk "insert hline")
   "ir" '(org-table-insert-row :wk "insert row")
   "iH" '(org-table-hline-and-move :wk "insert hline and move")
   "tf" '(org-table-toggle-formula-debugger :wk "toggle formula debugger")
   "to" '(org-table-toggle-coordinate-overlays :wk "toggle coordinate overlays"))

  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " c")
   "c" '(org-clock-cancel :wk "cancel clock")
   "d" '(org-clock-mark-default-task :wk "mark default task")
   "e" '(org-clock-modify-effort-estimate :wk "modify effort")
   "E" '(org-set-effort :wk "set effort")
   "g" '(org-clock-goto :wk "goto clock")
   "G" '(cmd! (org-clock-goto 'select) :wk "goto clock (select)")
   "l" '(#'+org/toggle-last-clock :wk "toggle last clock")
   "i" '(org-clock-in :wk "clock in")
   "I" '(org-clock-in-last :wk "clock in last")
   "o" '(org-clock-out :wk "clock out")
   "r" '(org-resolve-clocks :wk "resolve clocks")
   "R" '(org-clock-report :wk "clock report")
   "t" '(org-evaluate-time-range :wk "evaluate time range")
   "=" '(org-clock-timestamps-up :wk "timestamps up")
   "-" '(org-clock-timestamps-down :wk "timestamps down"))

  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " d")
   "d" '(org-deadline :wk "deadline")
   "s" '(org-schedule :wk "schedule")
   "t" '(org-time-stamp :wk "time stamp")
   "T" '(org-time-stamp-inactive :wk "inactive time stamp"))

  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " g")
   "g" '(consult-org-heading :wk "jump to heading")
   "G" '(consult-org-agenda :wk "jump in agenda files")
   "c" '(org-clock-goto :wk "goto clock")
   "C" '(cmd! (org-clock-goto 'select) :wk "goto clock (select)")
   "i" '(org-id-goto :wk "goto id")
   "r" '(org-refile-goto-last-stored :wk "goto last refile")
   "v" '(#'+org/goto-visible :wk "goto visible heading")
   "x" '(org-capture-goto-last-stored :wk "goto last capture"))

  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " l")
   "c" '(org-cliplink :wk "cliplink")
   "d" '(#'+org/remove-link :wk "remove link")
   "i" '(org-id-store-link :wk "store id link")
   "l" '(org-insert-link :wk "insert link")
   "L" '(org-insert-all-links :wk "insert all links")
   "s" '(org-store-link :wk "store link")
   "S" '(org-insert-last-stored-link :wk "insert last stored link")
   "t" '(org-toggle-link-display :wk "toggle link display")
   "y" '(#'+org/yank-link :wk "yank link"))

  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " P")
   "a" '(org-publish-all :wk "publish all")
   "f" '(org-publish-current-file :wk "publish current file")
   "p" '(org-publish :wk "publish")
   "P" '(org-publish-current-project :wk "publish current project")
   "s" '(org-publish-sitemap :wk "publish sitemap"))

  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " r")
   "." '(#'+org/refile-to-current-file :wk "refile to current file")
   "c" '(#'+org/refile-to-running-clock :wk "refile to running clock")
   "l" '(#'+org/refile-to-last-location :wk "refile to last location")
   "f" '(#'+org/refile-to-file :wk "refile to file")
   "o" '(#'+org/refile-to-other-window :wk "refile to other window")
   "O" '(#'+org/refile-to-other-buffer :wk "refile to other buffer")
   "v" '(#'+org/refile-to-visible :wk "refile to visible")
   "r" '(org-refile :wk "refile")
   "R" '(org-refile-reverse :wk "refile reverse"))

  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " s")
   "a" '(org-toggle-archive-tag :wk "toggle archive tag")
   "b" '(org-tree-to-indirect-buffer :wk "tree to indirect buffer")
   "c" '(org-clone-subtree-with-time-shift :wk "clone subtree")
   "d" '(org-cut-subtree :wk "cut subtree")
   "h" '(org-promote-subtree :wk "promote subtree")
   "j" '(org-move-subtree-down :wk "move subtree down")
   "k" '(org-move-subtree-up :wk "move subtree up")
   "l" '(org-demote-subtree :wk "demote subtree")
   "n" '(org-narrow-to-subtree :wk "narrow to subtree")
   "r" '(org-refile :wk "refile")
   "s" '(org-sparse-tree :wk "sparse tree")
   "A" '(org-archive-subtree-default :wk "archive subtree")
   "N" '(widen :wk "widen")
   "S" '(org-sort :wk "sort"))

  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " p")
   "d" '(org-priority-down :wk "priority down")
   "p" '(org-priority :wk "priority")
   "u" '(org-priority-up :wk "priority up"))

  (after! org-agenda
    (general-define-key
     :keymaps 'org-agenda-mode-map
     :states '(motion normal)
     "C-SPC" #'org-agenda-show-and-scroll-up)
    (general-define-key
     :keymaps 'org-agenda-mode-map
     :states '(normal visual emacs)
     :prefix doom-localleader-key
     "q" '(org-agenda-set-tags :wk "set tags")
     "r" '(org-agenda-refile :wk "refile")
     "t" '(org-agenda-todo :wk "todo"))
    (general-define-key
     :keymaps 'org-agenda-mode-map
     :states '(normal visual emacs)
     :prefix (concat doom-localleader-key " d")
     "d" '(org-agenda-deadline :wk "deadline")
     "s" '(org-agenda-schedule :wk "schedule"))
    (general-define-key
     :keymaps 'org-agenda-mode-map
     :states '(normal visual emacs)
     :prefix (concat doom-localleader-key " c")
     "c" '(org-agenda-clock-cancel :wk "clock cancel")
     "g" '(org-agenda-clock-goto :wk "clock goto")
     "i" '(org-agenda-clock-in :wk "clock in")
     "o" '(org-agenda-clock-out :wk "clock out")
     "r" '(org-agenda-clockreport-mode :wk "clock report mode")
     "s" '(org-agenda-show-clocking-issues :wk "clocking issues"))
    (general-define-key
     :keymaps 'org-agenda-mode-map
     :states '(normal visual emacs)
     :prefix (concat doom-localleader-key " p")
     "d" '(org-agenda-priority-down :wk "priority down")
     "p" '(org-agenda-priority :wk "priority")
     "u" '(org-agenda-priority-up :wk "priority up"))))

(defun +org-init-popup-rules-h ()
  ;; Doom's `set-popup-rules!' has no port here (window rules for org buffers
  ;; are left to the window manager); dropped.
  nil)

(defun +org-init-smartparens-h ()
  ;; Disable the slow defaults
  (provide 'smartparens-org))

;;; -- org packages -----------------------------------------------------------

(leaf toc-org ; auto-table of contents
  :ensure t
  :hook (org-mode . toc-org-enable)
  :config
  (setq toc-org-hrefify-default "gh")

  (defun +org-inhibit-scrolling-a (fn &rest args)
    "Prevent the jarring scrolling that occurs when the ToC is regenerated."
    (let ((p (set-marker (make-marker) (point)))
          (s (window-start)))
      (prog1 (apply fn args)
        (goto-char p)
        (set-window-start nil s t)
        (set-marker p nil))))
  (advice-add #'toc-org-insert-toc :around #'+org-inhibit-scrolling-a))

(leaf org-clock ; built-in
  :ensure nil
  :commands org-clock-save
  :init
  (setq org-clock-persist-file (expand-file-name "org-clock-save.el" (doom-profile-data-dir)))
  (defun +org--clock-load-a (&rest _)
    "Lazy load org-clock until its commands are used."
    (org-clock-load))
  (dolist (fn '(org-clock-in org-clock-out org-clock-in-last org-clock-goto org-clock-cancel))
    (advice-add fn :before #'+org--clock-load-a))
  :config
  (setq org-clock-persist 'history
        ;; Resume when clocking into task with open clock
        org-clock-in-resume t
        ;; Remove log if task was clocked for 0:00 (accidental clocking)
        org-clock-out-remove-zero-time-clocks t
        ;; The default value (5) is too conservative.
        org-clock-history-length 20)
  (add-hook 'kill-emacs-hook #'org-clock-save))

(defun org-eldoc-get-src-lang ()
  "Shim: org-eldoc was removed from modern org; get src block lang via org-babel."
  (car (org-babel-get-src-block-info t)))

;;; :lang org — src-block helpers reference org-eldoc-get-src-lang (shim above)

(leaf evil-org
  :ensure t
  :when (modulep! :editor evil +everywhere)
  :hook (org-mode . evil-org-mode)
  :hook (org-capture-mode . evil-insert-state)
  :init
  (defvar evil-org-retain-visual-state-on-shift t)
  (defvar evil-org-special-o/O '(table-row))
  (defvar evil-org-use-additional-insert t)
  :config
  (setq org-cycle-emulate-tab nil) ; don't insert TAB in non-insert modes
  (add-hook 'evil-org-mode-hook #'evil-normalize-keymaps)
  (evil-org-set-key-theme)
  ;; Only fold the current tree, rather than recursively; clear babel results
  ;; if point is inside a src block.
  (add-hook 'org-tab-first-hook #'+org-cycle-only-current-subtree-h 'append)
  (add-hook 'org-tab-first-hook #'+org-clear-babel-results-h 'append)
  (let-alist evil-org-movement-bindings
    (let ((Cright  (concat "C-" .right))
          (Cleft   (concat "C-" .left))
          (Cup     (concat "C-" .up))
          (Cdown   (concat "C-" .down))
          (CSright (concat "C-S-" .right))
          (CSleft  (concat "C-S-" .left))
          (CSup    (concat "C-S-" .up))
          (CSdown  (concat "C-S-" .down)))
      (general-define-key
       :keymaps 'evil-org-mode-map
       :states '(normal insert)
       [C-return]   #'+org/insert-item-below
       [C-S-return] #'+org/insert-item-above)
      (unless evil-disable-insert-state-bindings
        (general-define-key
         :keymaps 'evil-org-mode-map
         :states '(insert)
         Cright (lambda () (interactive) (if (org-at-table-p) (org-table-next-field) (org-end-of-line)))
         Cleft  (lambda () (interactive) (if (org-at-table-p) (org-table-previous-field) (org-beginning-of-line)))
         Cup    (lambda () (interactive) (if (org-at-table-p) (+org/table-previous-row) (org-up-element)))
         Cdown  (lambda () (interactive) (if (org-at-table-p) (org-table-next-row) (org-down-element)))
         CSright   #'org-shiftright
         CSleft    #'org-shiftleft
         CSup      #'org-shiftup
         CSdown    #'org-shiftdown
         "RET"     #'+org/return
         [S-return] #'+org/shift-return
         "S-RET"   #'+org/shift-return))
      (general-define-key
       :keymaps 'evil-org-mode-map
       :states '(normal)
       CSright   #'org-shiftright
       CSleft    #'org-shiftleft
       CSup      #'org-shiftup
       CSdown    #'org-shiftdown
       "gQ"  #'+org/reformat-at-point
       "za"  #'+org/toggle-fold
       "zA"  #'org-shifttab
       "zc"  #'+org/close-fold
       "zC"  #'outline-hide-subtree
       "zm"  #'+org/hide-next-fold-level
       "zM"  #'+org/close-all-folds
       "zn"  #'org-tree-to-indirect-buffer
       "zo"  #'+org/open-fold
       "zO"  #'outline-show-subtree
       "zr"  #'+org/show-next-fold-level
       "zR"  #'+org/open-all-folds
       "zi"  #'org-toggle-inline-images)
      (general-define-key
       :keymaps 'evil-org-mode-map
       :states '(motion)
       "RET"  #'+org/dwim-at-point
       "]h"  #'org-forward-heading-same-level
       "[h"  #'org-backward-heading-same-level
       "]l"  #'org-next-link
       "[l"  #'org-previous-link
       "]c"  #'org-babel-next-src-block
       "[c"  #'org-babel-previous-src-block)
      (general-define-key
       :keymaps 'org-read-date-minibuffer-local-map
       Cleft    (cmd! (org-eval-in-calendar '(calendar-backward-day 1)))
       Cright   (cmd! (org-eval-in-calendar '(calendar-forward-day 1)))
       Cup      (cmd! (org-eval-in-calendar '(calendar-backward-week 1)))
       Cdown    (cmd! (org-eval-in-calendar '(calendar-forward-week 1)))
       CSleft   (cmd! (org-eval-in-calendar '(calendar-backward-month 1)))
       CSright  (cmd! (org-eval-in-calendar '(calendar-forward-month 1)))
       CSup     (cmd! (org-eval-in-calendar '(calendar-backward-year 1)))
       CSdown   (cmd! (org-eval-in-calendar '(calendar-forward-year 1)))))))

(leaf evil-org-agenda
  :ensure nil
  :when (modulep! :editor evil +everywhere)
  :hook (org-agenda-mode . evil-org-agenda-mode)
  :config
  (evil-org-agenda-set-keys)
  (evil-define-key* 'motion evil-org-agenda-mode-map
    (kbd doom-leader-key) nil))

;;; -- org bootstrap ----------------------------------------------------------

(leaf org
  :ensure nil
  :preface
  ;; Set to nil so we can detect user changes to them later (and fall back on
  ;; defaults otherwise).
  (defvar org-directory nil)
  (defvar org-id-locations-file nil)
  (defvar org-attach-id-dir nil)
  (defvar org-babel-python-command nil)

  (setq org-persist-directory (expand-file-name "org/persist/" (doom-profile-cache-dir))
        org-publish-timestamp-directory (expand-file-name "org/timestamps/" (doom-profile-cache-dir))
        org-preview-latex-image-directory (expand-file-name "org/latex/" (doom-profile-cache-dir))
        ;; Recognize letters as list markers; must be set before org loads.
        org-list-allow-alphabetical t)

  ;; Make all default modules opt-in to lighten org's first-time load delay.
  (defvar org-modules nil)

  ;; Autoload common or module-specific link types from ol-* libs, so they're
  ;; available without needlessly loading them up front.
  (after! org
    (dolist (spec `((ol-info "info"
                     :follow org-info-open
                     :export org-info-export
                     :store org-info-store-link
                     :insert-description org-info-description-as-command)
                    ,@(when (modulep! :emacs eww)
                        '((ol-eww "eww"
                           :follow org-eww-open
                           :store org-eww-store-link)))
                    ,@(when (modulep! :tools biblo)
                        '((ol-bibtex "bibtex"
                           :follow org-bibtex-open
                           :store org-bibtex-store-link)))))
      (apply #'org-link-set-parameters (cadr spec) (cddr spec))
      (mapc (lambda (fn) (autoload fn (symbol-name (car spec))))
            (cl-delete-if #'keywordp (cddr spec)))))

  ;; Doom loads contrib/*.el for each enabled +flag; none of the org module
  ;; flags (+roam/+crypt/+journal/+pretty/...) are enabled in this config, so
  ;; no contrib files are loaded.

  ;; `show-paren-mode' causes flickering with indent overlays made by
  ;; `org-indent-mode'; disable it. Also disable `show-trailing-whitespace'.
  (add-hook 'org-mode-hook (lambda () (show-paren-local-mode -1)))
  (add-hook 'org-mode-hook (lambda () (setq-local show-trailing-whitespace nil)))

  (add-hook 'org-load-hook #'+org-init-org-directory-h)
  (add-hook 'org-load-hook #'+org-init-appearance-h)
  (add-hook 'org-load-hook #'+org-init-agenda-h)
  (add-hook 'org-load-hook #'+org-init-attachments-h)
  (add-hook 'org-load-hook #'+org-init-babel-h)
  (add-hook 'org-load-hook #'+org-init-babel-lazy-loader-h)
  (add-hook 'org-load-hook #'+org-init-capture-defaults-h)
  (add-hook 'org-load-hook #'+org-init-capture-frame-h)
  (add-hook 'org-load-hook #'+org-init-custom-links-h)
  (add-hook 'org-load-hook #'+org-init-export-h)
  (add-hook 'org-load-hook #'+org-init-habit-h)
  (add-hook 'org-load-hook #'+org-init-hacks-h)
  (add-hook 'org-load-hook #'+org-init-keybinds-h)
  (add-hook 'org-load-hook #'+org-init-popup-rules-h)
  (add-hook 'org-load-hook #'+org-init-smartparens-h)

  ;; HACK: Since 9.8, org-agenda fails to properly initialize on first
  ;;   invocation for some reason. Until this is sorted out, auto-reload it.
  (defun +org--reload-org-agenda-h ()
    (when (get-buffer-window nil t) ; make sure it's visible
      (remove-hook 'org-agenda-finalize-hook #'+org--reload-org-agenda-h)
      (org-agenda-redo nil)))
  (add-hook 'org-agenda-finalize-hook #'+org--reload-org-agenda-h)

  ;; Wait until an org-protocol link is opened via emacsclient to load
  ;; `org-protocol'.
  (defun +org--server-visit-files-a (fn files &rest args)
    "Load `org-protocol' lazily when an org-protocol link is opened."
    (if (not (cl-loop for var in files
                      if (string-match-p "org-protocol:/+" (car var))
                      return t))
        (apply fn files args)
      (require 'org-protocol)
      (apply fn files args)))
  (advice-add #'server-visit-files :around #'+org--server-visit-files-a)
  (after! org-protocol
    (advice-remove #'server-visit-files #'+org--server-visit-files-a))

  :config
  ;; HACK: `save-place' can position the cursor in an invisible region. Make
  ;;   it visible unless `org-inhibit-startup' is non-nil.
  (add-hook 'org-mode-hook
            (lambda ()
              (add-hook 'save-place-after-find-file-hook #'+org-make-last-point-visible-h nil t)))

  ;; Save target buffer after archiving a node.
  (setq org-archive-subtree-save-file-p t)

  ;; Don't number headings with these tags
  (setq org-num-face '(:inherit org-special-keyword :underline nil :weight bold)
        org-num-skip-tags '("noexport" "nonum"))

  ;; Other org properties are all-caps. Be consistent.
  (setq org-effort-property "EFFORT")

  ;; HACK: `org-id' doesn't check if `org-id-locations-file' exists or is
  ;;   writeable before trying to read/write to it, potentially throwing a
  ;;   file-error if it doesn't, which can leave Org in a broken state.
  (defun +org--fail-gracefully-a (fn &rest args)
    (with-demoted-errors "org-id-locations: %s"
      (apply fn args)))
  (dolist (fn '(org-id-locations-save org-id-locations-load))
    (advice-add fn :around #'+org--fail-gracefully-a))

  ;; Add the ability to play gifs, at point or throughout the buffer.
  (add-to-list 'org-startup-options '("inlinegifs" +org-startup-with-animated-gifs at-point))
  (add-to-list 'org-startup-options '("playgifs"   +org-startup-with-animated-gifs t))
  (add-hook 'org-mode-hook
    (defun +org-init-gifs-h ()
      (remove-hook 'post-command-hook #'+org-play-gif-at-point-h t)
      (remove-hook 'post-command-hook #'+org-play-all-gifs-h t)
      (pcase +org-startup-with-animated-gifs
        (`at-point (add-hook 'post-command-hook #'+org-play-gif-at-point-h nil t))
        (`t (add-hook 'post-command-hook #'+org-play-all-gifs-h nil t))))))

;;; -- org helpers (autoload/*.el) -------------------------------------------

(defun +org--toggle-inline-images-in-subtree (&optional beg end refresh)
  "Refresh inline image previews in the current heading/tree."
  (let* ((beg (or beg
                  (if (org-before-first-heading-p)
                      (save-excursion (point-min))
                    (save-excursion (org-back-to-heading) (point)))))
         (end (or end
                  (if (org-before-first-heading-p)
                      (save-excursion (org-next-visible-heading 1) (point))
                    (save-excursion (org-end-of-subtree) (point)))))
         (overlays (cl-remove-if-not (lambda (ov) (overlay-get ov 'org-image-overlay))
                                     (ignore-errors (overlays-in beg end)))))
    (dolist (ov overlays nil)
      (delete-overlay ov)
      (setq org-inline-image-overlays (delete ov org-inline-image-overlays)))
    (when (or refresh (not overlays))
      (org-link-preview nil beg end)
      t)))

(defun +org--insert-item (direction)
  (let ((context (org-element-lineage
                  (org-element-context)
                  '(table table-row headline inlinetask item plain-list)
                  t)))
    (pcase (org-element-type context)
      ;; Add a new list item (carrying over checkboxes if necessary)
      ((or `item `plain-list)
       (let ((orig-point (point)))
         (if (eq direction 'above)
             (org-beginning-of-item)
           (end-of-line))
         (let* ((ctx-item? (eq 'item (org-element-type context)))
                (ctx-cb (org-element-property :contents-begin context))
                (beginning-of-list? (and (not ctx-item?)
                                         (= ctx-cb orig-point)))
                (item-context (if beginning-of-list?
                                  (org-element-context)
                                context))
                (ictx-cb (org-element-property :contents-begin item-context))
                (empty? (and (eq direction 'below)
                             (or (not ictx-cb)
                                 (= ictx-cb
                                    (1+ (point))))))
                (pre-insert-point (point)))
           (when empty?
             (insert " "))
           (org-insert-item (org-element-property :checkbox context))
           (when empty?
             (delete-region pre-insert-point (1+ pre-insert-point))))))
      ;; Add a new table row
      ((or `table `table-row)
       (pcase direction
         ('below (save-excursion (org-table-insert-row t))
                 (org-table-next-row))
         ('above (save-excursion (org-shiftmetadown))
                 (+org/table-previous-row))))

      ;; Otherwise, add a new heading, carrying over any todo state, if
      ;; necessary.
      (_
       (let ((level (or (org-current-level) 1)))
         (pcase direction
           (`below
            (let (org-insert-heading-respect-content)
              (goto-char (line-end-position))
              (org-end-of-subtree)
              (insert "\n" (make-string level ?*) " ")))
           (`above
            (org-back-to-heading)
            (insert (make-string level ?*) " ")
            (save-excursion (insert "\n"))))
         (run-hooks 'org-insert-heading-hook)
         (when-let* ((todo-keyword (org-element-property :todo-keyword context))
                     (todo-type    (org-element-property :todo-type context)))
           (org-todo
            (cond ((eq todo-type 'done)
                   (car (+org-get-todo-keywords-for todo-keyword)))
                  (todo-keyword)
                  ('todo)))))))

    (when (org-invisible-p)
      (org-show-hidden-entry))
    (when (and (bound-and-true-p evil-local-mode)
               (not (evil-emacs-state-p)))
      (evil-insert 1))))

(defun +org-get-todo-keywords-for (&optional keyword)
  "Returns the list of todo keywords that KEYWORD belongs to."
  (when keyword
    (cl-loop for (type . keyword-spec)
             in (cl-remove-if-not #'listp org-todo-keywords)
             for keywords =
             (mapcar (lambda (x) (if (string-match "^\\([^(]+\\)(" x)
                                     (match-string 1 x)
                                   x))
                     keyword-spec)
             if (eq type 'sequence)
             if (member keyword keywords)
             return keywords)))

(defun +org/return ()
  "Call `org-return' then indent (if `electric-indent-mode' is on)."
  (interactive)
  (org-return electric-indent-mode))

(defun +org/dwim-at-point (&optional arg)
  "Do-what-I-mean at point.

If on a:
- checkbox list item or todo heading: toggle it.
- citation: follow it
- headline: cycle ARCHIVE subtrees, toggle latex fragments and inline images in
  subtree; update statistics cookies/checkboxes and ToCs.
- clock: update its time.
- footnote reference: jump to the footnote's definition
- footnote definition: jump to the first reference of this footnote
- timestamp: open an agenda view for the time-stamp date/range at point.
- table-row or a TBLFM: recalculate the table's formulas
- table-cell: clear it and go into insert mode. If this is a formula cell,
  recalculate it instead.
- babel-call: execute the source block
- statistics-cookie: update it.
- src block: execute it
- latex fragment: toggle it.
- link: follow it
- otherwise, refresh all inline images in current tree."
  (interactive "P")
  (if (button-at (point))
      (call-interactively #'push-button)
    (let* ((context (org-element-context))
           (type (org-element-type context)))
      (while (and context (memq type '(verbatim code bold italic underline strike-through subscript superscript)))
        (setq context (org-element-property :parent context)
              type (org-element-type context)))
      (pcase type
        ((or `citation `citation-reference)
         (org-cite-follow context arg))

        (`headline
         (cond ((memq (bound-and-true-p org-goto-map)
                      (current-active-maps))
                (org-goto-ret))
               ((and (fboundp 'toc-org-insert-toc)
                     (member "TOC" (org-get-tags)))
                (toc-org-insert-toc)
                (message "Updating table of contents"))
               ((string= "ARCHIVE" (car-safe (org-get-tags)))
                (org-force-cycle-archived))
               ((or (org-element-property :todo-type context)
                    (org-element-property :scheduled context))
                (org-todo
                 (if (eq (org-element-property :todo-type context) 'done)
                     (or (car (+org-get-todo-keywords-for (org-element-property :todo-keyword context)))
                         'todo)
                   'done))))
         (org-update-checkbox-count)
         (org-update-parent-todo-statistics)
         (when (and (fboundp 'toc-org-insert-toc)
                    (member "TOC" (org-get-tags)))
           (toc-org-insert-toc)
           (message "Updating table of contents"))
         (let* ((beg (if (org-before-first-heading-p)
                         (line-beginning-position)
                       (save-excursion (org-back-to-heading) (point))))
                (end (if (org-before-first-heading-p)
                         (line-end-position)
                       (save-excursion (org-end-of-subtree) (point))))
                (overlays (ignore-errors (overlays-in beg end)))
                (latex-overlays
                 (cl-find-if (lambda (o) (eq (overlay-get o 'org-overlay-type) 'org-latex-overlay))
                             overlays))
                (image-overlays
                 (cl-find-if (lambda (o) (overlay-get o 'org-image-overlay))
                             overlays)))
           (+org--toggle-inline-images-in-subtree beg end)
           (if (or image-overlays latex-overlays)
               (org-clear-latex-preview beg end)
             (org--latex-preview-region beg end))))

        (`clock (org-clock-update-time-maybe))

        (`footnote-reference
         (org-footnote-goto-definition (org-element-property :label context)))

        (`footnote-definition
         (org-footnote-goto-previous-reference (org-element-property :label context)))

        ((or `planning `timestamp)
         (org-follow-timestamp-link))

        ((or `table `table-row)
         (if (org-at-TBLFM-p)
             (org-table-calc-current-TBLFM)
           (ignore-errors
             (save-excursion
               (goto-char (org-element-property :contents-begin context))
               (org-call-with-arg 'org-table-recalculate (or arg t))))))

        (`table-cell
         (org-table-blank-field)
         (org-table-recalculate arg)
         (when (and (string-empty-p (string-trim (org-table-get-field)))
                    (bound-and-true-p evil-local-mode))
           (evil-change-state 'insert)))

        (`babel-call
         (org-babel-lob-execute-maybe))

        (`statistics-cookie
         (save-excursion (org-update-statistics-cookies arg)))

        ((or `src-block `inline-src-block)
         (org-babel-execute-src-block arg))

        ((or `latex-fragment `latex-environment)
         (org-latex-preview arg))

        (`link
         (let* ((lineage (org-element-lineage context '(link) t))
                (path (org-element-property :path lineage)))
           (if (and (not org-return-follows-link)
                    (or (null path) (image-supported-file-p path))
                    (functionp
                     (plist-get (cdr (assoc (org-element-property :type lineage)
                                            org-link-parameters))
                                :preview)))
               (+org--toggle-inline-images-in-subtree
                (org-element-property :begin lineage)
                (org-element-property :end lineage))
             (org-open-at-point arg))))

        ((guard (org-element-property :checkbox (org-element-lineage context '(item) t)))
         (org-toggle-checkbox))

        (`paragraph
         (+org--toggle-inline-images-in-subtree))

        (_
         (if (or (org-in-regexp org-ts-regexp-both nil t)
                 (org-in-regexp org-tsr-regexp-both nil t)
                 (org-in-regexp org-link-any-re nil t))
             (call-interactively #'org-open-at-point)
           (+org--toggle-inline-images-in-subtree
            (org-element-property :begin context)
            (org-element-property :end context))))))))

(defun +org/shift-return (&optional arg)
  "Insert a literal newline, or dwim in tables.
Executes `org-table-copy-down' if in table."
  (interactive "p")
  (if (org-at-table-p)
      (org-table-copy-down arg)
    (org-return nil arg)))

(defun +org/insert-item-below (count)
  "Inserts a new heading, table cell or item below the current one."
  (interactive "p")
  (dotimes (_ count) (+org--insert-item 'below)))

(defun +org/insert-item-above (count)
  "Inserts a new heading, table cell or item above the current one."
  (interactive "p")
  (dotimes (_ count) (+org--insert-item 'above)))

(defun +org/toggle-last-clock (arg)
  "Toggles last clocked item.

Clock out if an active clock is running (or cancel it if prefix ARG is non-nil).

If no clock is active, then clock into the last item."
  (interactive "P")
  (require 'org-clock)
  (cond ((org-clocking-p)
         (if arg
             (org-clock-cancel)
           (org-clock-out)))
        ((and (null org-clock-history)
              (or (org-on-heading-p)
                  (org-at-item-p))
              (y-or-n-p "No active clock. Clock in on current item?"))
         (org-clock-in))
        ((org-clock-in-last arg))))

(defun +org/reformat-at-point ()
  "Reformat the element at point.

If in an org src block, invokes the :editor format module's org-block command.
If in an org table, realign the cells with `org-table-align'.
Otherwise, falls back to `org-fill-paragraph' to reflow paragraphs."
  (interactive)
  (let ((element (org-element-at-point)))
    (cond ((doom-region-active-p)
           (if (and (modulep! :editor format)
                    (fboundp '+format/org-blocks-in-region))
               (call-interactively #'+format/org-blocks-in-region)
             (message ":editor format is disabled, skipping reformatting of org-blocks")))
          ((org-in-src-block-p nil element)
           (unless (and (modulep! :editor format)
                        (fboundp '+format/org-block))
             (user-error ":editor format module is disabled, ignoring reformat..."))
           (call-interactively #'+format/org-block))
          ((org-at-table-p)
           (save-excursion (org-table-align)))
          ((call-interactively #'org-fill-paragraph)))))

;;; Folds
(defalias #'+org/toggle-fold #'+org-cycle-only-current-subtree-h)

(defun +org/open-fold ()
  "Open the current fold (not but its children)."
  (interactive)
  (+org/toggle-fold t))

(defalias #'+org/close-fold #'outline-hide-subtree)

(defun +org/close-all-folds (&optional level)
  "Close all folds in the buffer (or below LEVEL)."
  (interactive "p")
  (outline-hide-sublevels (or level 1)))

(defun +org/open-all-folds (&optional level)
  "Open all folds in the buffer (or up to LEVEL)."
  (interactive "P")
  (if (integerp level)
      (outline-hide-sublevels level)
    (outline-show-all)))

(defun +org--get-foldlevel ()
  (let ((max 1))
    (save-restriction
      (narrow-to-region (window-start) (window-end))
      (save-excursion
        (goto-char (point-min))
        (while (not (eobp))
          (org-next-visible-heading 1)
          (when (memq (get-char-property (line-end-position)
                                         'invisible)
                      '(outline org-fold-outline))
            (let ((level (org-outline-level)))
              (when (> level max)
                (setq max level))))))
      max)))

(defun +org/show-next-fold-level (&optional count)
  "Decrease the fold-level of the visible area of the buffer. This unfolds
another level of headings on each invocation."
  (interactive "p")
  (let ((new-level (+ (+org--get-foldlevel) (or count 1))))
    (outline-hide-sublevels new-level)
    (message "Folded to level %s" new-level)))

(defun +org/hide-next-fold-level (&optional count)
  "Increase the global fold-level of the visible area of the buffer. This folds
another level of headings on each invocation."
  (interactive "p")
  (let ((new-level (max 1 (- (+org--get-foldlevel) (or count 1)))))
    (outline-hide-sublevels new-level)
    (message "Folded to level %s" new-level)))
;;; -- org hooks & tab handlers ---------------------------------------------

(defun +org-indent-maybe-h ()
  "Indent the current item (header or item), if possible.
Made for `org-tab-first-hook' in evil-mode."
  (interactive)
  (cond ((not (and (bound-and-true-p evil-local-mode)
                   (evil-insert-state-p)))
         nil)
        ((and (bound-and-true-p org-cdlatex-mode)
              (or (org-inside-LaTeX-fragment-p)
                  (org-inside-latex-macro-p)))
         nil)
        ((org-at-item-p)
         (if (eq this-command 'org-shifttab)
             (org-outdent-item-tree)
           (org-indent-item-tree))
         t)
        ((org-at-heading-p)
         (ignore-errors
           (if (eq this-command 'org-shifttab)
               (org-promote)
             (org-demote)))
         t)
        ((org-in-src-block-p t)
         (save-window-excursion
           (org-babel-do-in-edit-buffer
            (call-interactively #'indent-for-tab-command)))
         t)
        ((and (save-excursion
                (skip-chars-backward " \t")
                (bolp))
              (org-in-subtree-not-table-p))
         (call-interactively #'tab-to-tab-stop)
         t)))

(defun +org-yas-expand-maybe-h ()
  "Expand a yasnippet snippet, if trigger exists at point or region is active.
Made for `org-tab-first-hook'."
  (when (and (modulep! :editor snippets)
             (require 'yasnippet nil t)
             (bound-and-true-p yas-minor-mode))
    (let ((major-mode (if (org-in-src-block-p t)
                          (org-src-get-lang-mode (org-eldoc-get-src-lang))
                        major-mode))
          (org-src-tab-acts-natively nil) ; causes breakages
          (yas-indent-line 'fixed))
      (cond ((and (or (not (bound-and-true-p evil-local-mode))
                      (evil-insert-state-p)
                      (evil-emacs-state-p))
                  (or (and (bound-and-true-p yas--tables)
                           (gethash major-mode yas--tables))
                      (or (get 'yas-reload-all 'reloaded)
                          (progn (yas-reload-all)
                                 (put 'yas-reload-all 'reloaded t)
                                 t)))
                  (yas--templates-for-key-at-point))
             (yas-expand)
             t)
            ((use-region-p)
             (yas-insert-snippet)
             t)))))

(defun +org-cycle-only-current-subtree-h (&optional arg)
  "Toggle the local fold at the point, and no deeper.
`org-cycle's standard behavior is to cycle between three levels: collapsed,
subtree and whole document. This is slow, especially in larger org buffers.
Most of the time I just want to peek into the current subtree."
  (interactive "P")
  (unless (or (eq this-command 'org-shifttab)
              (and (bound-and-true-p org-cdlatex-mode)
                   (or (org-inside-LaTeX-fragment-p)
                       (org-inside-latex-macro-p))))
    (save-excursion
      (org-beginning-of-line)
      (let (invisible-p)
        (when (and (org-at-heading-p)
                   (or org-cycle-open-archived-trees
                       (not (member org-archive-tag (org-get-tags))))
                   (or (not arg)
                       (setq invisible-p
                             (memq (get-char-property (line-end-position)
                                                      'invisible)
                                   '(outline org-fold-outline)))))
          (unless invisible-p
            (setq org-cycle-subtree-status 'subtree))
          (org-cycle-internal-local)
          t)))))

(defun +org-make-last-point-visible-h ()
  "Unfold subtree around point if saveplace places us in a folded region."
  (and (not org-inhibit-startup)
       (not org-inhibit-startup-visibility-stuff)
       (let ((buf (current-buffer)))
         (unless (doom-temp-buffer-p buf)
           (run-at-time 0.1 nil (lambda ()
                                  (when (buffer-live-p buf)
                                    (with-current-buffer buf
                                      (org-reveal '(4))))))))))

(defun +org-remove-occur-highlights-h ()
  "Remove org occur highlights on ESC in normal mode."
  (when org-occur-highlights
    (org-remove-occur-highlights)
    t))

(defun +org-delete-backward-char-and-realign-table-maybe-h ()
  "Ensure deleting characters with backspace doesn't deform the table cell."
  (when (eq major-mode 'org-mode)
    (org-check-before-invisible-edit 'delete-backward)
    (save-match-data
      (when (and (org-at-table-p)
                 (not (org-region-active-p))
                 (string-match-p "|" (buffer-substring (line-beginning-position) (point)))
                 (looking-at-p ".*?|"))
        (let ((pos (point))
              (noalign (looking-at-p "[^|\n\r]*  |"))
              (c org-table-may-need-update))
          (delete-char -1)
          (unless overwrite-mode
            (skip-chars-forward "^|")
            (insert " ")
            (goto-char (1- pos)))
          (when noalign (setq org-table-may-need-update c)))
        t))))

(defun +org-clear-babel-results-h ()
  "Remove the results block for the org babel block at point."
  (when (and (org-in-src-block-p t)
             (org-babel-where-is-src-block-result))
    (org-babel-remove-result)
    t))

;;; -- org capture helpers (autoload/org-capture.el) -------------------------

(defvar +org-capture-fn #'org-capture
  "Command to use to initiate org-capture.")

(defvar +org-capture-frame-parameters
  `((name . "doom-capture")
    (width . 70)
    (height . 25)
    (transient . t)
    ,@(when (featurep :system 'linux)
        `((window-system . ,(if (boundp 'pgtk-initialized) 'pgtk 'x))
          (display . ,(or (getenv "WAYLAND_DISPLAY")
                          (getenv "DISPLAY")
                          ":0"))))
    ,(if (featurep :system 'macos) '(menu-bar-lines . 1)))
  "Frame parameters for the org-capture frame.")

(defun +org-capture-cleanup-frame-h ()
  "Closes the org-capture frame once done adding an entry."
  (when (and (+org-capture-frame-p)
             (not org-capture-is-refiling))
    (delete-frame nil t)))

(defun +org-capture-frame-p (&rest _)
  "Return t if the current frame is an org-capture frame opened by
`+org-capture/open-frame'."
  (and (equal (alist-get 'name +org-capture-frame-parameters)
              (frame-parameter nil 'name))
       (frame-parameter nil 'transient)))

(defun +org-capture-todo-file ()
  "Expand `+org-capture-todo-file' from `org-directory'.
If it is an absolute path return `+org-capture-todo-file' verbatim."
  (expand-file-name +org-capture-todo-file org-directory))

(defun +org-capture-notes-file ()
  "Expand `+org-capture-notes-file' from `org-directory'.
If it is an absolute path return `+org-capture-notes-file' verbatim."
  (expand-file-name +org-capture-notes-file org-directory))

(defun +org--capture-local-root (path)
  (let ((filename (file-name-nondirectory path)))
    (expand-file-name
     filename
     (or (locate-dominating-file (file-truename default-directory)
                                 filename)
         (doom-project-root)
         (user-error "Couldn't detect a project")))))

(defun +org-capture-project-todo-file ()
  "Find the nearest `+org-capture-todo-file' in a parent directory, otherwise,
opens a blank one at the project root. Throws an error if not in a project."
  (+org--capture-local-root +org-capture-todo-file))

(defun +org-capture-project-notes-file ()
  "Find the nearest `+org-capture-notes-file' in a parent directory, otherwise,
opens a blank one at the project root. Throws an error if not in a project."
  (+org--capture-local-root +org-capture-notes-file))

(defun +org-capture-project-changelog-file ()
  "Find the nearest `+org-capture-changelog-file' in a parent directory,
otherwise, opens a blank one at the project root. Throws an error if not in a
project."
  (+org--capture-local-root +org-capture-changelog-file))

(defun +org--capture-ensure-heading (headings &optional initial-level)
  (if (not headings)
      (widen)
    (let ((initial-level (or initial-level 1)))
      (if (and (re-search-forward (format org-complex-heading-regexp-format
                                          (regexp-quote (car headings)))
                                  nil t)
               (= (org-current-level) initial-level))
          (progn
            (beginning-of-line)
            (org-narrow-to-subtree))
        (goto-char (point-max))
        (unless (and (bolp) (eolp)) (insert "\n"))
        (insert (make-string initial-level ?*)
                " " (car headings) "\n")
        (beginning-of-line 0))
      (+org--capture-ensure-heading (cdr headings) (1+ initial-level)))))

(defun +org--project-name ()
  "Return the current project's directory name."
  (file-name-nondirectory
   (directory-file-name (or (doom-project-root) default-directory))))

(defun +org--capture-central-file (file project)
  (let ((file (expand-file-name file org-directory)))
    (set-buffer (org-capture-target-buffer file))
    (org-capture-put-target-region-and-position)
    (widen)
    (goto-char (point-min))
    ;; Find or create the project heading
    (+org--capture-ensure-heading
     (append (org-capture-get :parents)
             (list project (org-capture-get :heading))))))

(defun +org-capture-central-project-todo-file ()
  (+org--capture-central-file
   +org-capture-projects-file (+org--project-name)))

(defun +org-capture-central-project-notes-file ()
  (+org--capture-central-file
   +org-capture-projects-file (+org--project-name)))

(defun +org-capture-central-project-changelog-file ()
  (+org--capture-central-file
   +org-capture-projects-file (+org--project-name)))

;;; -- org link helpers (autoload/org-link.el) -------------------------------

(defun +org-link-preview-attachment-fn (ov link elem)
  "Preview images managed by org-download and org-attach in Org buffers."
  (let ((link
         (pcase (org-element-property :type elem)
           ("download"
            (expand-file-name
             link (or (if (require 'org-download nil t) org-download-image-dir)
                      default-directory)))
           ("attachment"
            (require 'org-attach)
            (org-attach-expand link))
           (_ (expand-file-name link default-directory)))))
    (when (and (file-readable-p link)
               (image-supported-file-p link))
      (org-link-preview-file ov link elem))))

(defun +org-link-preview-image-data-fn (ov data elem)
  "Preview base64 encoded images in Org buffers."
  (save-match-data
    (when-let*
        (((string-match "^image/\\([^;]+\\);base64,\\(.+\\)" data))
         (raw-data (base64-decode-string (match-string 2 data)))
         (type (or (image-type-from-data raw-data) (match-string 1 data)))
         (cache-file (expand-file-name
                      (format "imagedata.%s.%s"
                              (sha1 data)
                              type)
                      +org-preview-dir)))
      (unless (file-exists-p cache-file)
        (with-temp-file cache-file
          (insert raw-data)))
      (when (file-readable-p cache-file)
        (org-link-preview-file ov cache-file elem)))))

(defun +org-link-preview-image-url-fn (ov link elem)
  "Preview remote images (http/https links) in Org buffers."
  (when (and (image-supported-file-p link)
             (not (eq org-display-remote-inline-images 'skip)))
    (if-let* ((raw-link (org-element-property :raw-link elem))
              (buf (url-retrieve-synchronously raw-link))
              (cache-file (expand-file-name
                           (format "image.%s.%s"
                                   (sha1 raw-link)
                                   (file-name-extension link))
                           +org-preview-dir)))
        (progn
          (unless (file-exists-p cache-file)
            (make-directory +org-preview-dir t)
            (with-temp-file cache-file
              (insert
               (with-current-buffer buf
                 (goto-char (point-min))
                 (re-search-forward "\r?\n\r?\n" nil t)
                 (buffer-substring-no-properties (point) (point-max))))))
          (when (file-readable-p cache-file)
            (org-link-preview-file ov cache-file elem)))
      (message "Download of image \"%s\" failed" link)
      nil)))

(defvar +org--gif-timers nil)
(defun +org-play-gif-at-point-h ()
  "Play the gif at point, while the cursor remains there (looping)."
  (dolist (timer +org--gif-timers (setq +org--gif-timers nil))
    (when (timerp (cdr timer))
      (cancel-timer (cdr timer)))
    (image-animate (car timer) nil 0))
  (when-let* ((ov (cl-find-if
                   (lambda (it) (overlay-get it 'org-image-overlay))
                   (overlays-at (point))))
              (dov (overlay-get ov 'display))
              (pt  (point)))
    (when (image-animated-p dov)
      (push (cons
             dov (run-with-idle-timer
                  0.5 nil
                  (lambda (dov)
                    (when (equal
                           ov (cl-find-if
                               (lambda (it) (overlay-get it 'org-image-overlay))
                               (overlays-at (point))))
                      (message "playing gif")
                      (image-animate dov nil t)))
                  dov))
            +org--gif-timers))))

(defun +org-play-all-gifs-h ()
  "Continuously play all gifs in the visible buffer."
  (dolist (ov (overlays-in (point-min) (point-max)))
    (when-let* (((overlay-get ov 'org-image-overlay))
                (dov (overlay-get ov 'display))
                ((image-animated-p dov))
                (w (selected-window)))
      (while-no-input
        (run-with-idle-timer
         0.3 nil
         (lambda (dov)
           (when (pos-visible-in-window-p (overlay-start ov) w nil)
             (unless (plist-get (cdr dov) :animate-buffer)
               (image-animate dov))))
         dov)))))

(defun +org/remove-link ()
  "Unlink the text at point."
  (interactive)
  (unless (org-in-regexp org-link-bracket-re 1)
    (user-error "No link at point"))
  (save-excursion
    (let ((label (if (match-end 2)
                     (match-string-no-properties 2)
                   (org-link-unescape (match-string-no-properties 1)))))
      (delete-region (match-beginning 0) (match-end 0))
      (insert label))))

(defun +org/yank-link ()
  "Copy the url at point to the clipboard.
If on top of an Org link, will only copy the link component."
  (interactive)
  (let ((url (thing-at-point 'url)))
    (kill-new (or url (user-error "No URL at point")))
    (message "Copied link: %s" url)))

;;; -- org babel & lookup handlers (autoload/org-babel.el) -------------------

(defun +org-eval-handler (beg end)
  "Evaluate the region; if it's inside a src block, evaluate that instead."
  (save-excursion
    (if (not (cl-loop for pos in (list beg (point) end)
                      if (save-excursion (goto-char pos) (org-in-src-block-p t))
                      return (goto-char pos)))
        (message "Nothing to evaluate at point")
      (let* ((element (org-element-at-point))
             (block-beg (save-excursion
                          (goto-char (org-babel-where-is-src-block-head element))
                          (line-beginning-position 2)))
             (block-end (save-excursion
                          (goto-char (org-element-property :end element))
                          (skip-chars-backward " \t\n")
                          (line-beginning-position)))
             (beg (if beg (max beg block-beg) block-beg))
             (end (if end (min end block-end) block-end))
             (lang (or (org-eldoc-get-src-lang)
                       (user-error "No lang specified for this src block"))))
        (cond ((and (string-prefix-p "jupyter-" lang)
                    (require 'jupyter nil t))
               (jupyter-eval-region beg end))
               ((save-window-excursion
                 (org-babel-do-in-edit-buffer
                   (eval-region beg end)))))))))

(defun +org-lookup-definition-handler (identifier)
  (when (org-in-src-block-p t)
    (let ((mode (org-src-get-lang-mode
                 (or (org-eldoc-get-src-lang)
                     (user-error "No lang specified for this src block")))))
      (cond ((and (eq mode 'emacs-lisp-mode)
                  (fboundp '+emacs-lisp-lookup-definition))
             (+emacs-lisp-lookup-definition identifier)
             'deferred)
            ((user-error "Definition lookup in SRC blocks isn't supported yet"))))))

(defun +org-lookup-references-handler (_identifier)
  (when (org-in-src-block-p t)
    (user-error "References lookup in SRC blocks isn't supported yet")))

(defun +org-lookup-documentation-handler (identifier)
  (when (org-in-src-block-p t)
    (let ((mode (org-src-get-lang-mode
                 (or (org-eldoc-get-src-lang)
                     (user-error "No lang specified for this src block"))))
          (info (org-babel-get-src-block-info t)))
      (cond ((string-prefix-p "jupyter-" (car info))
             (and (require 'jupyter nil t)
                  (call-interactively #'jupyter-inspect-at-point)
                  (display-buffer (help-buffer))
                  'deferred))
            ((and (eq mode 'emacs-lisp-mode)
                  (fboundp '+emacs-lisp-lookup-documentation))
             (+emacs-lisp-lookup-documentation identifier)
             'deferred)
            ((user-error "Documentation lookup in SRC blocks isn't supported yet"))))))

(defun +org/remove-result-blocks (remove-all)
  "Remove all result blocks located after current point."
  (interactive "P")
  (let ((pos (point)))
    (org-babel-map-src-blocks nil
      (if (or remove-all (< pos end-block))
          (org-babel-remove-result)))))

;;; -- org tables / refile / attach commands ----------------------------------

(defun +org/table-previous-row ()
  "Go to the previous row (same column) in the current table. Before doing so,
re-align the table if necessary."
  (interactive)
  (org-table-maybe-eval-formula)
  (org-table-maybe-recalculate-line)
  (if (and org-table-automatic-realign
           org-table-may-need-update)
      (org-table-align))
  (let ((col (org-table-current-column)))
    (beginning-of-line 0)
    (when (or (not (org-at-table-p)) (org-at-table-hline-p))
      (beginning-of-line))
    (org-table-goto-column col)
    (skip-chars-backward "^|\n\r")
    (when (org-looking-at-p " ")
      (forward-char))))

(defun +org/refile-to-current-file (arg &optional file)
  "Refile current heading to elsewhere in the current buffer.
If prefix ARG, copy instead of move."
  (interactive "P")
  (let ((org-refile-targets `((,file :maxlevel . 10)))
        (org-refile-use-outline-path 'file)
        (org-refile-keep arg)
        current-prefix-arg)
    (call-interactively #'org-refile)))

(defun +org/refile-to-file (arg file)
  "Refile current heading to a particular org file.
If prefix ARG, copy instead of move."
  (interactive
   (list current-prefix-arg
         (read-file-name "Select file to refile to: "
                         default-directory
                         (buffer-file-name (buffer-base-buffer))
                         t nil
                         (lambda (f) (string-match-p "\\.org$" f)))))
  (+org/refile-to-current-file arg file))

(defun +org/refile-to-other-window (arg)
  "Refile current heading to an org buffer visible in another window.
If prefix ARG, copy instead of move."
  (interactive "P")
  (let ((org-refile-keep arg)
        org-refile-targets
        current-prefix-arg)
    (dolist (win (delq (selected-window) (window-list)))
      (with-selected-window win
        (let ((file (buffer-file-name (buffer-base-buffer))))
          (and (eq major-mode 'org-mode)
               file
               (cl-pushnew (cons file (cons :maxlevel 10))
                           org-refile-targets)))))
    (call-interactively #'org-refile)))

(defun +org/refile-to-other-buffer (arg)
  "Refile current heading to another, living org buffer.
If prefix ARG, copy instead of move."
  (interactive "P")
  (let ((org-refile-keep arg)
        org-refile-targets
        current-prefix-arg)
    (dolist (buf (cl-remove-if-not
                  (lambda (b) (with-current-buffer b (derived-mode-p 'org-mode)))
                  (buffer-list)))
      (when-let* ((file (buffer-file-name (buffer-base-buffer buf))))
        (cl-pushnew (cons file (cons :maxlevel 10))
                    org-refile-targets)))
    (call-interactively #'org-refile)))

(defun +org/refile-to-running-clock (arg)
  "Refile current heading to the currently clocked in task.
If prefix ARG, copy instead of move."
  (interactive "P")
  (unless (bound-and-true-p org-clock-current-task)
    (user-error "No active clock to refile to"))
  (let ((org-refile-keep arg))
    (org-refile 2)))

(defun +org/refile-to-last-location (arg)
  "Refile current heading to the last node you refiled to.
If prefix ARG, copy instead of move."
  (interactive "P")
  (or (assoc (plist-get org-bookmark-names-plist :last-refile)
             bookmark-alist)
      (user-error "No saved location to refile to"))
  (let ((org-refile-keep arg)
        (completing-read-function
         (lambda (_p _coll _pred _rm _ii _h default &rest _)
           default)))
    (org-refile)))

(defun +org/refile-to-visible ()
  "Refile current heading as first child of visible heading selected with Avy."
  (interactive)
  (when-let* ((marker (+org-headline-avy)))
    (let* ((buffer (marker-buffer marker))
           (filename
            (buffer-file-name (or (buffer-base-buffer buffer)
                                  buffer)))
           (heading
            (org-with-point-at marker
              (org-get-heading 'no-tags 'no-todo)))
           ;; Won't work with target buffers whose filename is nil
           (rfloc (list heading filename nil marker)))
      (dlet ((org-after-refile-insert-hook (cons #'org-reveal org-after-refile-insert-hook)))
        (org-refile nil nil rfloc)))))

(defun +org-headline-avy ()
  (require 'avy)
  (save-excursion
    (when-let* ((org-reverse-note-order t)
                (pos (avy-with avy-goto-line (avy-jump (rx bol (1+ "*") (1+ blank))))))
      (when (integerp (car pos))
        ;; If avy is aborted with "C-g", it returns `t', so we know it was NOT
        ;; aborted when it returns an int.
        (copy-marker (car pos))))))

(defun +org/goto-visible ()
  (interactive)
  (goto-char (+org-headline-avy)))

(defun +org/find-file-in-attachments ()
  "Open a file from `org-attach-id-dir'."
  (interactive)
  (dired org-attach-id-dir))

(defun +org/attach-file-and-insert-link (path)
  "Downloads the file at PATH and insert an org link at point.
PATH (a string) can be an url, a local file path, or a base64 encoded datauri."
  (interactive "sUri/file: ")
  (unless (eq major-mode 'org-mode)
    (user-error "Not in an org buffer"))
  (require 'org-download)
  (condition-case-unless-debug e
      (let ((raw-uri (url-unhex-string path)))
        (cond ((string-match-p "^data:image/png;base64," path)
               (org-download-dnd-base64 path nil))
              ((image-type-from-file-name raw-uri)
               (org-download-image raw-uri))
              ((let ((new-path (expand-file-name (org-download--fullname raw-uri))))
                 ;; Download the file
                 (if (string-match-p (concat "^" (regexp-opt '("http" "https" "nfs" "ftp" "file")) ":/") path)
                     (url-copy-file raw-uri new-path)
                   (copy-file path new-path))
                 ;; insert the link
                 (org-download-insert-link raw-uri new-path)))))
    (error
     (user-error "Failed to attach file: %s" (error-message-string e)))))
;;; ===================================================================
;;; :lang python
;;; ===================================================================

(defcustom +python-ipython-command '("ipython" "-i" "--simple-prompt" "--no-color-info")
  "Command to initialize the ipython REPL for `+python/open-ipython-repl'."
  :safe #'list-of-strings-p
  :type '(repeat string)
  :group '+python)

(defcustom +python-jupyter-command '("jupyter" "console" "--simple-prompt")
  "Command to initialize the jupyter REPL for `+python/open-jupyter-repl'."
  :safe #'list-of-strings-p
  :type '(repeat string)
  :group '+python)

(with-eval-after-load 'projectile
  (add-to-list 'projectile-project-root-files "setup.py")
  (add-to-list 'projectile-project-root-files "requirements.txt")
  (add-to-list 'projectile-project-root-files "pyproject.toml"))

(leaf python
  :ensure nil
  :mode ("/\\(?:Pipfile\\|\\.?flake8\\)\\'" . conf-mode)
  :init
  (setq python-environment-directory (doom-profile-cache-dir)
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
   :states '(normal visual emacs)
   :prefix doom-localleader-key
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
   :states '(normal visual emacs)
   :prefix (concat doom-localleader-key " e")
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
   :states '(normal visual emacs)
   :prefix doom-localleader-key
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

;;; -- rust helpers (autoload/rust.el) ---------------------------------------

(defun +rust-cargo-project-p ()
  "Return t if this is a cargo project."
  (locate-dominating-file buffer-file-name "Cargo.toml"))

(autoload 'rustic-run-cargo-command "rustic-cargo")
(defun +rust/cargo-audit ()
  "Run 'cargo audit' for the current project."
  (interactive)
  (rustic-run-cargo-command "cargo audit"))

;;; ===================================================================
;;; :lang go
;;; ===================================================================

(defun +go-common-config (mode)
  (when (modulep! +lsp)
    (add-hook (intern (format "%s-hook" mode)) #'lsp-deferred))
  (let ((map (intern (format "%s-map" mode))))
    (general-define-key
     :keymaps map :states '(normal visual emacs)
     :prefix doom-localleader-key
     "a" '(go-tag-add :wk "add struct tags")
     "d" '(go-tag-remove :wk "remove struct tags")
     "e" '(#'+go/play-buffer-or-region :wk "play buffer/region")
     "i" '(go-goto-imports :wk "go to imports")
     "h." '(godoc-at-point :wk "godoc at point")
     "ria" '(go-import-add :wk "add import")
     "br" '(cmd! (compile "go run .") :wk "go run .")
     "bb" '(cmd! (compile "go build") :wk "go build")
     "bc" '(cmd! (compile "go clean") :wk "go clean")
     "gf" '(#'+go/generate-file :wk "go generate file")
     "gd" '(#'+go/generate-dir :wk "go generate dir")
     "ga" '(#'+go/generate-all :wk "go generate all")
     "tt" '(#'+go/test-rerun :wk "rerun last test")
     "ta" '(#'+go/test-all :wk "test all")
     "ts" '(#'+go/test-single :wk "test single")
     "tn" '(#'+go/test-nested :wk "test nested")
     "tf" '(#'+go/test-file :wk "test file")
     "tg" '(go-gen-test-dwim :wk "gen test dwim")
     "tG" '(go-gen-test-all :wk "gen test all")
     "te" '(go-gen-test-exported :wk "gen test exported")
     "tbs" '(#'+go/bench-single :wk "bench single")
     "tba" '(#'+go/bench-all :wk "bench all"))))

(leaf go-mode
  :ensure t
  :config
  (+go-common-config 'go-mode))

(leaf go-ts-mode ; 29.1+ only
  :ensure nil
  :when (modulep! +tree-sitter)
  :mode ("/go\\.mod\\'" . go-mod-ts-mode-maybe)
  :config
  (+go-common-config 'go-ts-mode))

(leaf go-tag
  :ensure t
  :commands (go-tag-add go-tag-remove))

(leaf go-gen-test
  :ensure t
  :commands (go-gen-test-dwim go-gen-test-all go-gen-test-exported))

(leaf gorepl-mode
  :ensure t
  :commands gorepl-run-load-current-file)

;;; -- go helpers (autoload.el) ----------------------------------------------

(defun +go--spawn (cmd)
  (save-selected-window
    (compile cmd)))

(defun +go--assert-buffer-visiting ()
  (unless buffer-file-name
    (user-error "Not in a file-visiting buffer")))

(defvar +go-test-last nil
  "The last test run.")

(defun +go--run-tests (args)
  (let ((cmd (concat "go test -test.v " args)))
    (setq +go-test-last (concat "cd " default-directory ";" cmd))
    (+go--spawn cmd)))

(defun +go/test-rerun ()
  "Rerun last run test."
  (interactive)
  (if +go-test-last
      (+go--spawn +go-test-last)
    (+go/test-all)))

(defun +go/test-all ()
  "Run all tests for this project."
  (interactive)
  (+go--run-tests ""))

(defun +go/test-nested ()
  "Run all tests in current directory and below, recursively."
  (interactive)
  (+go--run-tests "./..."))

(defun +go/test-single ()
  "Run single test at point."
  (interactive)
  (+go--assert-buffer-visiting)
  (unless (string-match-p "_test\\.go$" buffer-file-name)
    (user-error "Must be in a *_test.go file"))
  (save-excursion
    (save-match-data
      (unless (re-search-backward "^func[ ]+\\(([[:alnum:]]*?[ ]?[*]?[[:alnum:]]+)[ ]+\\)?\\(Test[[:alnum:]_]+\\)(.*)" nil t)
        (user-error "No detectable test at or after point"))
      (+go--run-tests (concat "-run" "='^\\Q" (match-string-no-properties 2) "\\E$'")))))

(defun +go/test-file ()
  "Run all tests in current file."
  (interactive)
  (+go--assert-buffer-visiting)
  (unless (string-match-p "_test\\.go$" buffer-file-name)
    (user-error "Must be in a *_test.go file"))
  (save-excursion
    (save-match-data
      (goto-char (point-min))
      (let (func-list)
        (while (re-search-forward "^func[ ]+\\(([[:alnum:]]*?[ ]?[*]?[[:alnum:]]+)[ ]+\\)?\\(Test[[:alnum:]_]+\\)(.*)" nil t)
          (push (match-string-no-properties 2) func-list))
        (unless func-list
          (user-error "No detectable tests in this file"))
        (+go--run-tests (concat "-run" "='^(" (string-join func-list "|")  ")$'"))))))

(defun +go/bench-all ()
  "Run all benchmarks in project."
  (interactive)
  (+go--run-tests "-test.run=NONE -test.bench=\".*\""))

(defun +go/bench-single ()
  "Run benchmark at point."
  (interactive)
  (if (string-match "_test\\.go" buffer-file-name)
      (save-excursion
        (re-search-backward "^func[ ]+\\(([[:alnum:]]*?[ ]?[*]?[[:alnum:]]+)[ ]+\\)?\\(Benchmark[[:alnum:]_]+\\)(.*)")
        (+go--run-tests (concat "-test.run=NONE -test.bench" "='^\\Q" (match-string-no-properties 2) "\\E$'")))
    (error "Must be in a _test.go file")))

(defun +go--generate (dir args)
  (unless (file-directory-p dir)
    (user-error "Directory does not exist: %s" dir))
  (+go--spawn
   (format "cd %s && go generate %s"
           (shell-quote-argument dir)
           args)))

(defun +go/generate-file ()
  "Run 'go generate' for the current file."
  (interactive)
  (+go--assert-buffer-visiting)
  (+go--generate default-directory
                 (file-name-nondirectory buffer-file-name)))

(defun +go/generate-dir ()
  "Run 'go generate' for the current directory, recursively."
  (interactive)
  (+go--generate default-directory "./..."))

(defun +go/generate-all (&optional arg)
  "Run 'go generate' for the entire project.
Will prompt for the project if you're not in one or if the prefix ARG is
non-nil."
  (interactive "P")
  (let ((proot (or (doom-project-root)
                   (if arg (read-directory-name "Project root: ") nil))))
    (if proot
        (+go--generate (file-truename proot) "./...")
      (user-error "Not in a valid project"))))

(defun +go/play-buffer-or-region (&optional beg end)
  "Evaluate active selection or buffer in the Go playground."
  (interactive "r")
  (if (use-region-p)
      (go-play-region beg end)
    (go-play-buffer)))

;;; ===================================================================
;;; :lang cc
;;; ===================================================================

(defvar +cc-default-include-paths
  (list "include"
        "includes")
  "A list of default relative paths which will be searched for up from the
current file. Paths can be absolute. This is ignored if your project has a
compilation database.")

(defvar +cc-default-header-file-mode 'c-mode
  "Fallback major mode for .h files if all other heuristics fail (in
`+cc-c-c++-objc-mode').")

(leaf cc-mode
  :ensure nil
  :mode ("\\.mm\\'" . objc-mode)
  ;; Use `c-mode'/`c++-mode'/`objc-mode' depending on heuristics
  :mode ("\\.h\\'" . +cc-c-c++-objc-mode)
  ;; Ensure find-file-at-point recognizes system libraries in C modes.
  :hook ((c-mode-hook c++-mode-hook objc-mode-hook) . +cc-init-ffap-integration-h)
  :init
  (after! ffap
    (add-to-list 'ffap-alist '(c-mode . ffap-c-mode))
    (add-to-list 'ffap-alist '(c-ts-mode . ffap-c-mode))
    (add-to-list 'ffap-alist '(c++-ts-mode . ffap-c++-mode)))
  :config
  ;; HACK: cc-mode adds null entries to `major-mode-remap-defaults'; leave
  ;;   tree-sitter remapping to the user. (set-tree-sitter! has no port here.)
  (add-to-list 'find-sibling-rules '("/\\([^/]+\\)\\.c\\(c\\|pp\\)?\\'" "\\1.h\\(h\\|pp\\)?\\'"))
  (add-to-list 'find-sibling-rules '("/\\([^/]+\\)\\.h\\(h\\|pp\\)?\\'" "\\1.c\\(c\\|pp\\)?\\'"))

  ;; HACK: Suppress 'Args out of range' error when multiple modifications are
  ;;   performed at once in a `c++-mode' buffer, e.g. with `iedit'.
  (defun +cc--suppress-silly-errors-a (fn &rest args)
    (ignore-errors (apply fn args)))
  (advice-add #'c-after-change-mark-abnormal-strings :around #'+cc--suppress-silly-errors-a)

  ;; Custom style, based off of linux
  (setq c-basic-offset tab-width
        c-backspace-function #'delete-backward-char)

  (c-add-style
   "doom" '((c-comment-only-line-offset . 0)
            (c-hanging-braces-alist (brace-list-open)
                                    (brace-entry-open)
                                    (substatement-open after)
                                    (block-close . c-snug-do-while)
                                    (arglist-cont-nonempty))
            (c-cleanup-list brace-else-brace)
            (c-offsets-alist
             (knr-argdecl-intro . 0)
             (substatement-open . 0)
             (substatement-label . 0)
             (statement-cont . +)
             (case-label . +)
             ;; align args with open brace OR don't indent at all
             (brace-list-intro . 0)
             (brace-list-close . -)
             (arglist-intro . +)
             (arglist-close +cc-lineup-arglist-close 0)
             ;; don't over-indent lambda blocks
             (inline-open . 0)
             (inlambda . 0)
             ;; indent access keywords +1 level, and properties beneath them
             ;; another level
             (access-label . -)
             (inclass +cc-c++-lineup-inclass +)
             (label . 0))))

  (when (listp c-default-style)
    (setf (alist-get 'other c-default-style) "doom")))

(leaf cmake-mode
  :ensure t
  :config
  (when (modulep! +lsp)
    (add-hook 'cmake-mode-hook #'lsp-deferred)))

(leaf glsl-mode
  :ensure t
  :config
  (when (modulep! +lsp)
    (add-hook 'glsl-mode-hook #'lsp-deferred)))

(leaf cuda-mode
  :ensure t
  :config
  (when (modulep! +lsp)
    (add-hook 'cuda-mode-hook #'lsp-deferred)))

(leaf demangle-mode
  :ensure t
  :hook llvm-mode)

(when (modulep! +lsp)
  (add-hook 'c-mode-hook #'lsp-deferred)
  (add-hook 'c-ts-mode-hook #'lsp-deferred)
  (add-hook 'c++-mode-hook #'lsp-deferred)
  (add-hook 'c++-ts-mode-hook #'lsp-deferred)
  (add-hook 'objc-mode-hook #'lsp-deferred)

  (after! lsp-clangd
    ;; Prevent clangd from consuming all your cores indexing larger projects
    ;; and grinding your system to a halt.
    (cl-pushnew (format "-j=%d" (max 1 (/ (doom-system-cpus) 2)))
                lsp-clients-clangd-args)))

;;; -- cc helpers (autoload.el) ----------------------------------------------

(defun +cc--re-search-for (regexp)
  (save-excursion
    (save-restriction
      (save-match-data
        (widen)
        (goto-char (point-min))
        (re-search-forward regexp magic-mode-regexp-match-limit t)))))

(defun +cc-c-c++-objc-mode ()
  "Uses heuristics to detect `c-mode', `objc-mode' or `c++-mode'.

1. Checks if there are nearby cpp/cc/m/mm files with the same name.
2. Checks for ObjC and C++-specific keywords and libraries.
3. Falls back to `+cc-default-header-file-mode', if set.
4. Otherwise, activates `c-mode'.

This is meant to replace `c-or-c++-mode' (introduced in Emacs 26.1)."
  (funcall
   (major-mode-remap
    (let ((base (file-name-sans-extension (buffer-file-name (buffer-base-buffer)))))
      (cond ((or (file-exists-p (concat base ".cpp"))
                 (file-exists-p (concat base ".cc")))
             'c++-mode)
            ((or (file-exists-p (concat base ".m"))
                 (file-exists-p (concat base ".mm"))
                 (+cc--re-search-for
                  (concat "^[ \t\r]*\\(?:"
                          "@\\(?:class\\|interface\\|property\\|end\\)\\_>"
                          "\\|#import +<Foundation/Foundation.h>"
                          "\\|[-+] ([a-zA-Z0-9_]+)"
                          "\\)")))
             'objc-mode)
            ((+cc--re-search-for
              (let ((id "[a-zA-Z0-9_]+") (ws "[ \t\r]+") (ws-maybe "[ \t\r]*"))
                (concat "^" ws-maybe "\\(?:"
                        "using" ws "\\(?:namespace" ws "std;\\|std::\\)"
                        "\\|" "namespace" "\\(?:" ws id "\\)?" ws-maybe "{"
                        "\\|" "class"     ws id ws-maybe "[:{\n]"
                        "\\|" "template"  ws-maybe "<.*>"
                        "\\|" "#include"  ws-maybe "<\\(?:string\\|iostream\\|map\\)>"
                        "\\)")))
             'c++-mode)
            ((functionp +cc-default-header-file-mode)
             +cc-default-header-file-mode)
            ('c-mode))))))

(defun +cc-resolve-include-paths ()
  (cl-loop with path = (or buffer-file-name default-directory)
           for dir in +cc-default-include-paths
           if (file-name-absolute-p dir)
           collect dir
           else if (locate-dominating-file
                    path (lambda (d) (file-exists-p (expand-file-name dir d))))
           collect (expand-file-name dir it)))

(defvar +cc--project-includes-alist nil)
(defun +cc-init-ffap-integration-h ()
  "Takes the local project include paths and registers them with ffap.
This way, `find-file-at-point' will know where to find most header files."
  (when-let* ((project-root (or (and (fboundp 'lsp-workspace-root)
                                     (lsp-workspace-root))
                                (doom-project-root))))
    (require 'ffap)
    (make-local-variable 'ffap-c-path)
    (make-local-variable 'ffap-c++-path)
    (cl-loop for dir in (or (cdr (assoc project-root +cc--project-includes-alist))
                            (+cc-resolve-include-paths))
             do (add-to-list (pcase major-mode
                               ((or `c-mode `c-ts-mode) 'ffap-c-path)
                               ((or `c++-mode `c++-ts-mode) 'ffap-c++-path))
                             (expand-file-name dir project-root)))))

(defun +cc-c++-lineup-inclass (langelem)
  "Indent inclass lines one level further than access modifier keywords."
  (and (eq major-mode 'c++-mode)
       (or (assoc 'access-label c-syntactic-context)
           (save-excursion
             (save-match-data
               (re-search-backward
                "\\(?:p\\(?:ublic\\|r\\(?:otected\\|ivate\\)\\)\\)"
                (c-langelem-pos langelem) t))))
       '++))

(defun +cc-lineup-arglist-close (langelem)
  "Line up the closing brace in an arglist with the opening brace IF cursor is
preceded by the opening brace or a comma (disregarding whitespace in between)."
  (when (save-excursion
          (save-match-data
            (skip-chars-backward " \t\n" (c-langelem-pos langelem))
            (memq (char-before) (list ?, ?\( ?\;))))
    (c-lineup-arglist langelem)))
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
     :keymaps map :states '(normal visual emacs)
     :prefix doom-localleader-key
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
               (not (doom-point-in-comment-p))
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

  ;; autoclose backticks
  (when (boundp 'sp-local-pair)
    (sp-local-pair 'sh-mode "`" "`" :unless '(sp-point-before-word-p sp-point-before-same-p))))

;;; -- sh helpers (autoload.el) ----------------------------------------------

(defun +sh--match-variables-in-quotes (limit)
  "Search for variables in double-quoted strings bounded by LIMIT."
  (with-syntax-table sh-mode-syntax-table
    (let (res)
      (while
          (and (setq res
                     (re-search-forward
                      "[^\\]\\(\\$\\)\\({.+?}\\|\\<[a-zA-Z0-9_]+\\|[@*#!]\\)"
                      limit t))
               (not (eq (nth 3 (syntax-ppss)) ?\"))))
      res)))

(defun +sh--match-command-subst-in-quotes (limit)
  "Search for variables in double-quoted strings bounded by LIMIT."
  (with-syntax-table sh-mode-syntax-table
    (let (res)
      (while
          (and (setq res
                     (re-search-forward "[^\\]\\(\\$(.+?)\\|`.+?`\\)"
                                        limit t))
               (not (eq (nth 3 (syntax-ppss)) ?\"))))
      res)))

(defun +sh/open-repl ()
  "Open a shell REPL."
  (interactive)
  (require 'sh-script)
  (let ((dest-sh (symbol-name sh-shell)))
    (dlet ((sh-shell-file dest-sh))
      (sh-shell-process t))
    (with-current-buffer "*shell*"
      (rename-buffer (format "*shell [%s]*" dest-sh))
      (current-buffer))))

(defun +sh-lookup-documentation-handler ()
  "Look up documentation in `man' or `woman'."
  (interactive)
  (require 'man)
  (let ((input (Man-default-man-entry)))
    (if (executable-find "man")
        (let* ((input (Man-translate-references input))
               (buffer (Man-getpage-in-background input)))
          (when (buffer-live-p buffer)
            (switch-to-buffer buffer)))
      (woman input t)
      (current-buffer))))

;;; ===================================================================
;;; :lang markdown
;;; ===================================================================

(defgroup +markdown nil
  "Enhances support for Markdown in Emacs."
  :group 'lisp)

(defcustom +markdown-compile-functions
  '(+markdown-compile-marked
    +markdown-compile-pandoc
    +markdown-compile-markdown
    +markdown-compile-multimarkdown)
  "A list of functions for `markdown-open' or `markdown-preview' to execute.

Stops at the first one to return non-nil. Each function takes three argument.
The beginning position of the region to capture, the end position, and the
output buffer."
  :type '(repeat function)
  :group '+markdown)

(defun +markdown-common-config (mode &rest extra-modes)
  (sp-local-pair (cons mode extra-modes) "`" "`"
                 :unless '(:add sp-point-before-word-p sp-point-before-same-p))

  (when (modulep! +lsp)
    (dolist (m (cons mode extra-modes))
      (add-hook (intern (format "%s-hook" m)) #'lsp-deferred)))

  (let ((map (intern (format "%s-map" mode))))
    (general-define-key
     :keymaps map :states '(normal visual emacs)
     :prefix doom-localleader-key
     "'" '(markdown-edit-code-block :wk "edit code block")
     "o" '(markdown-open :wk "open")
     "p" '(markdown-preview :wk "preview")
     "e" '(markdown-export :wk "export")
     "iT" '(markdown-toc-generate-toc :wk "table of contents")
     "ii" '(markdown-insert-image :wk "image")
     "il" '(markdown-insert-link :wk "link")
     "i-" '(markdown-insert-hr :wk "hr")
     "i1" '(markdown-insert-header-atx-1 :wk "heading 1")
     "i2" '(markdown-insert-header-atx-2 :wk "heading 2")
     "i3" '(markdown-insert-header-atx-3 :wk "heading 3")
     "i4" '(markdown-insert-header-atx-4 :wk "heading 4")
     "i5" '(markdown-insert-header-atx-5 :wk "heading 5")
     "i6" '(markdown-insert-header-atx-6 :wk "heading 6")
     "iC" '(markdown-insert-gfm-code-block :wk "code block")
     "iP" '(markdown-pre-region :wk "pre region")
     "iQ" '(markdown-blockquote-region :wk "blockquote region")
     "i[" '(markdown-insert-gfm-checkbox :wk "checkbox")
     "ib" '(markdown-insert-bold :wk "bold")
     "ic" '(markdown-insert-code :wk "inline code")
     "ie" '(markdown-insert-italic :wk "italic")
     "if" '(markdown-insert-footnote :wk "footnote")
     "ih" '(markdown-insert-header-dwim :wk "header dwim")
     "ik" '(markdown-insert-kbd :wk "kbd")
     "ip" '(markdown-insert-pre :wk "pre")
     "iq" '(markdown-insert-blockquote :wk "blockquote")
     "is" '(markdown-insert-strike-through :wk "strike through")
     "it" '(markdown-insert-table :wk "table")
     "iw" '(markdown-insert-wiki-link :wk "wiki link")
     "te" '(markdown-toggle-math :wk "inline latex")
     "tf" '(markdown-toggle-fontify-code-blocks-natively :wk "code highlights")
     "ti" '(markdown-toggle-inline-images :wk "inline images")
     "tl" '(markdown-toggle-url-hiding :wk "url hiding")
     "tm" '(markdown-toggle-markup-hiding :wk "markup hiding")
     "tw" '(markdown-toggle-wiki-links :wk "wiki links")
     "tx" '(markdown-toggle-gfm-checkbox :wk "gfm checkbox")))
  (when (modulep! +grip)
    (let ((map (intern (format "%s-map" mode))))
      (general-define-key
       :keymaps map :states '(normal visual emacs)
       :prefix doom-localleader-key
       "p" '(grip-mode :wk "grip preview")))))

(leaf markdown-mode
  :ensure t
  :mode ("/README\\(?:\\.md\\)?\\'" . gfm-mode)
  :init
  (setq markdown-italic-underscore t
        markdown-gfm-additional-languages '("sh")
        markdown-make-gfm-checkboxes-buttons t
        markdown-fontify-whole-heading-line t
        markdown-fontify-code-blocks-natively t

        ;; `+markdown-compile' offers support for many transpilers (see
        ;; `+markdown-compile-functions'), which it tries until one succeeds.
        markdown-command #'+markdown-compile
        markdown-open-command
        (cond ((featurep :system 'macos) "open")
              ((featurep :system 'linux) "xdg-open"))

        ;; A sensible and simple default preamble for markdown exports that
        ;; takes after the github aesthetic (plus highlightjs syntax coloring).
        markdown-content-type "application/xhtml+xml"
        markdown-css-paths
        '("https://cdn.jsdelivr.net/npm/github-markdown-css/github-markdown.min.css"
          "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release/build/styles/github.min.css")
        markdown-xhtml-header-content
        (concat "<meta name='viewport' content='width=device-width, initial-scale=1, shrink-to-fit=no'>"
                "<style> body { box-sizing: border-box; max-width: 740px; width: 100%; margin: 40px auto; padding: 0 10px; } </style>"
                "<script id='MathJax-script' async src='https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js'></script>"
                "<script src='https://cdn.jsdelivr.net/gh/highlightjs/cdn-release/build/highlight.min.js'></script>"
                "<script>document.addEventListener('DOMContentLoaded', () => { document.body.classList.add('markdown-body'); document.querySelectorAll('pre[lang] > code').forEach((code) => { code.classList.add(code.parentElement.lang); }); document.querySelectorAll('pre > code').forEach((code) => { hljs.highlightBlock(code); }); });</script>")
        ;; Disabled to prevent accidentally clicking links while focusing Emacs
        ;; or a markdown buffer.
        markdown-mouse-follow-link nil)

  :config
  (+markdown-common-config 'markdown-mode 'gfm-mode)

  ;; Don't trigger autofill in code blocks (see `auto-fill-mode')
  (add-hook 'markdown-mode-hook
            (lambda ()
              (setq-local fill-nobreak-predicate
                          (cons #'markdown-code-block-at-point-p
                                fill-nobreak-predicate))))

  ;; HACK: Prevent mis-fontification of YAML metadata blocks in `markdown-mode'
  ;;   which occurs when the first line contains a colon in it.
  (defun +markdown-disable-front-matter-fontification-a (&rest _)
    (ignore (goto-char (point-max))))
  (advice-add #'markdown-match-generic-metadata :override #'+markdown-disable-front-matter-fontification-a)

  ;; HACK: markdown-mode calls a major mode without inhibiting its hooks, which
  ;;   could contain expensive functionality. Suppress it to speed up
  ;;   fontification.
  (defun +markdown-optimize-src-buffer-modes-a (fn &rest args)
    (delay-mode-hooks (apply fn args)))
  (advice-add #'markdown-fontify-code-block-natively :around #'+markdown-optimize-src-buffer-modes-a))

(leaf markdown-toc
  :ensure t
  :commands markdown-toc-generate-toc)

(leaf edit-indirect
  :ensure t
  :defer t)

(leaf evil-markdown
  :ensure t
  :when (modulep! :editor evil +everywhere)
  :hook (markdown-mode . evil-markdown-mode)
  :config
  (add-hook 'evil-markdown-mode-hook #'evil-normalize-keymaps)
  (general-define-key
   :keymaps 'evil-markdown-mode-map
   :states '(normal)
   "TAB" #'markdown-cycle
   [backtab] #'markdown-shifttab
   "M-r" #'browse-url-of-file)
  (unless evil-disable-insert-state-bindings
    (general-define-key
     :keymaps 'evil-markdown-mode-map
     :states '(insert)
     "M-*" #'markdown-insert-list-item
     "M-b" #'markdown-insert-bold
     "M-i" #'markdown-insert-italic
     "M-`" #'+markdown/insert-del
     "M--" #'markdown-insert-hr))
  (general-define-key
   :keymaps 'evil-markdown-mode-map
   :states '(motion)
   "]h"  #'markdown-next-visible-heading
   "[h"  #'markdown-previous-visible-heading
   "[p"  #'markdown-promote
   "]p"  #'markdown-demote
   "[l"  #'markdown-previous-link
   "]l"  #'markdown-next-link))

;;; -- markdown helpers (autoload.el) -----------------------------------------

(defun +markdown-compile (beg end output-buffer)
  "Compile markdown into html.

Runs `+markdown-compile-functions' until the first function to return non-nil,
otherwise throws an error."
  (or (run-hook-with-args-until-success '+markdown-compile-functions
                                        beg end output-buffer)
      (user-error "No markdown program could be found. Install marked, pandoc, markdown or multimarkdown.")))

(defun +markdown-compile-marked (beg end output-buffer)
  "Compiles markdown with the marked program, if available.
Returns its exit code."
  (when (executable-find "marked")
    (apply #'call-process-region
           beg end "marked" nil output-buffer nil
           (when (eq major-mode 'gfm-mode)
             (list "--gfm" "--tables" "--breaks")))))

(defun +markdown-compile-pandoc (beg end output-buffer)
  "Compiles markdown with the pandoc program, if available.
Returns its exit code."
  (when (executable-find "pandoc")
    (call-process-region beg end "pandoc" nil output-buffer nil
                         "-f" "markdown"
                         "-t" "html"
                         "--mathjax")))

(defun +markdown-compile-multimarkdown (beg end output-buffer)
  "Compiles markdown with the multimarkdown program, if available. Returns its
exit code."
  (when (executable-find "multimarkdown")
    (call-process-region beg end "multimarkdown" nil output-buffer)))

(defun +markdown-compile-markdown (beg end output-buffer)
  "Compiles markdown using the Markdown.pl script (or markdown executable), if
available. Returns its exit code."
  (when-let* ((exe (or (executable-find "Markdown.pl")
                       (executable-find "markdown"))))
    (call-process-region beg end exe nil output-buffer nil)))

(defun +markdown/insert-del ()
  "Surround region in github strike-through delimiters."
  (interactive)
  (let ((regexp "\\(^\\|[^\\]\\)\\(\\(~\\{2\\}\\)\\([^ \n\t\\]\\|[^ \n\t]\\(?:.\\|\n[^\n]\\)*?[^\\ ]\\)\\(\\3\\)\\)")
        (delim "~~"))
    (if (markdown-use-region-p)
        ;; Active region
        (cl-destructuring-bind (beg . end)
            (markdown-unwrap-things-in-region
             (region-beginning) (region-end)
             regexp 2 4)
          (markdown-wrap-or-insert delim delim nil beg end))
      ;; Bold markup removal, bold word at point, or empty markup insertion
      (if (thing-at-point-looking-at regexp)
          (markdown-unwrap-thing-at-point nil 2 4)
        (markdown-wrap-or-insert delim delim 'word nil nil)))))

;;; ===================================================================
;;; :lang json
;;; ===================================================================

(leaf json-mode
  :ensure t
  :mode "\\.js\\(?:on\\|[hl]int\\(?:rc\\)?\\)\\'"
  :config
  (when (modulep! +lsp)
    (add-hook 'json-mode-hook #'lsp-deferred))
  (general-define-key
   :keymaps 'json-mode-map
   :states '(normal visual emacs)
   :prefix doom-localleader-key
   "p" '(json-mode-show-path :wk "show path")
   "t" '(json-toggle-boolean :wk "toggle boolean")
   "d" '(json-mode-kill-path :wk "kill path")
   "x" '(json-nullify-sexp :wk "nullify sexp")
   "+" '(json-increment-number-at-point :wk "increment number")
   "-" '(json-decrement-number-at-point :wk "decrement number")
   "f" '(json-mode-beautify :wk "beautify")))

;;; ===================================================================
;;; :lang yaml
;;; ===================================================================

(leaf yaml-mode
  :ensure t
  :mode "Procfile\\'"
  :config
  (when (modulep! +lsp)
    (add-hook 'yaml-mode-hook #'lsp-deferred))
  ;; HACK: `yaml-ts-mode' doesn't implement any indentation (falling back to
  ;;   `indent-relative'), so borrow `yaml-mode's.
  (add-hook 'yaml-ts-mode-hook
            (lambda () (setq-local indent-line-function #'yaml-indent-line))))

;;; ===================================================================
;;; :lang javascript
;;; ===================================================================

(with-eval-after-load 'projectile
  (add-to-list 'projectile-project-root-files "package.json")
  (add-to-list 'projectile-globally-ignored-directories "node_modules")
  (add-to-list 'projectile-globally-ignored-directories "flow-typed"))

(defun +javascript-common-config (mode)
  (unless (eq mode 'nodejs-repl-mode)
    (when (modulep! +lsp)
      (add-hook (intern (format "%s-hook" mode)) #'lsp-deferred))))

(leaf js
  :ensure nil
  :mode ("\\.[mc]?js\\'" . js-mode)
  :mode ("\\.es6\\'" . js-mode)
  :mode ("\\.pac\\'" . js-mode)
  :config
  (+javascript-common-config 'js-mode)
  (when (modulep! +tree-sitter)
    (+javascript-common-config 'js-ts-mode))
  (setq js-chain-indent t))

(leaf typescript-mode
  :ensure t
  :unless (modulep! +tree-sitter)
  :mode "\\.ts\\'"
  :config
  (+javascript-common-config 'typescript-mode))

(leaf typescript-ts-mode ; 29.1+ only
  :ensure nil
  :when (modulep! +tree-sitter)
  :mode "\\.ts\\'"
  :mode ("\\.[tj]sx\\'" . tsx-ts-mode)
  :config
  (+javascript-common-config 'typescript-ts-mode)
  (+javascript-common-config 'tsx-ts-mode))

;; Parse node stack traces in the compilation buffer
(with-eval-after-load 'compilation
  (add-to-list 'compilation-error-regexp-alist 'node)
  (add-to-list 'compilation-error-regexp-alist-alist
               '(node "^[[:blank:]]*at \\(.*(\\|\\)\\(.+?\\):\\([[:digit:]]+\\):\\([[:digit:]]+\\)"
                 2 3 4)))

(leaf nodejs-repl
  :ensure t
  :config
  (+javascript-common-config 'nodejs-repl-mode))

;;; -- javascript helpers (autoload.el) ---------------------------------------

(defun +javascript-add-npm-path-h ()
  "Add node_modules/.bin to `exec-path'."
  (when-let* ((search-directory (or (doom-project-root) default-directory))
              (node-modules-parent (locate-dominating-file search-directory "node_modules/"))
              (node-modules-dir (expand-file-name "node_modules/.bin/" node-modules-parent)))
    (make-local-variable 'exec-path)
    (add-to-list 'exec-path node-modules-dir)
    (doom-log ":lang:javascript: add %s to $PATH" (expand-file-name "node_modules/" node-modules-parent))))

;; Approximation of doom's `def-project-mode! +javascript-npm-mode': add
;; node_modules/.bin to exec-path when in an npm project.
(defun +javascript--add-npm-path-maybe-h ()
  (when (and (derived-mode-p 'html-mode 'css-mode 'web-mode 'markdown-mode
                             'js-mode 'js-ts-mode 'json-mode 'json-ts-mode
                             'typescript-mode 'typescript-ts-mode 'tsx-ts-mode)
             (locate-dominating-file default-directory "package.json"))
    (+javascript-add-npm-path-h)))
(add-hook 'find-file-hook #'+javascript--add-npm-path-maybe-h)

(defun +javascript/open-repl ()
  "Open a Javascript REPL via `nodejs-repl'."
  (interactive)
  (nodejs-repl)
  (current-buffer))

;;; ===================================================================
;;; :lang web
;;; ===================================================================

(leaf emmet-mode
  :ensure t
  :preface (defvar emmet-mode-keymap (make-sparse-keymap))
  :hook ((css-mode web-mode html-mode nxml-mode) . emmet-mode)
  :config
  (when (require 'yasnippet nil t)
    (add-hook 'emmet-mode-hook #'yas-minor-mode-on))
  (setq emmet-move-cursor-between-quotes t)
  (general-define-key
   :keymaps 'emmet-mode-keymap
   :states '(visual)
   [tab] #'emmet-wrap-with-markup)
  (general-define-key
   :keymaps 'emmet-mode-keymap
   [tab] #'+web/indent-or-yas-or-emmet-expand
   "M-E" #'emmet-expand-line))

(leaf web-mode
  :ensure t
  :mode "\\.[px]?html?\\'"
  :mode "\\.\\(?:tpl\\|blade\\)\\(?:\\.php\\)?\\'"
  :mode "\\.erb\\'"
  :mode "\\.[lh]?eex\\'"
  :mode "\\.jsp\\'"
  :mode "\\.as[cp]x\\'"
  :mode "\\.ejs\\'"
  :mode "\\.hbs\\'"
  :mode "\\.mustache\\'"
  :mode "\\.svelte\\'"
  :mode "\\.twig\\'"
  :mode "\\.jinja2?\\'"
  :mode "\\.eco\\'"
  :mode "wp-content/themes/.+/.+\\.php\\'"
  :mode "templates/.+\\.php\\'"
  :init
  ;; If the user has installed `vue-mode' then, by appending this to
  ;; `auto-mode-alist' rather than prepending it, its autoload will have
  ;; priority over this one.
  (add-to-list 'auto-mode-alist '("\\.vue\\'" . web-mode) 'append)
  :config
  (setq web-mode-enable-html-entities-fontification t
        web-mode-auto-close-style 1)

  (after! smartparens
    (defun +web-is-auto-close-style-3 (_id action _context)
      (and (eq action 'insert)
           (eq web-mode-auto-close-style 3)))
    (sp-local-pair 'web-mode "<" ">" :unless '(:add +web-is-auto-close-style-3))

    ;; let smartparens handle these
    (setq web-mode-enable-auto-quoting nil
          web-mode-enable-auto-pairing t)

    ;; 1. Remove web-mode auto pairs whose end pair starts with a letter
    ;;    (truncated autopairs like <?p and hp ?>). Smartparens handles these
    ;;    better.
    ;; 2. Strips out extra closing pairs to prevent redundant characters
    ;;    inserted by smartparens.
    (dolist (alist web-mode-engines-auto-pairs)
      (setcdr alist
              (cl-loop for pair in (cdr alist)
                       unless (string-match-p "^[a-z-]" (cdr pair))
                       collect (cons (car pair)
                                     (string-trim-right (cdr pair)
                                                        "\\(?:>\\|]\\|}\\)+\\'")))))
    (cl-callf2 delq nil web-mode-engines-auto-pairs))

  (add-to-list 'web-mode-engines-alist '("elixir" . "\\.eex\\'"))
  (add-to-list 'web-mode-engines-alist '("phoenix" . "\\.[lh]eex\\'"))

  ;; Use // instead of /* as the default comment delimited in JS
  (setf (alist-get "javascript" web-mode-comment-formats nil nil #'equal)
        "//")

  (defun +web--fix-js-comments-h ()
    "Fix comment handling in `web-mode' for JavaScript."
    (when (member web-mode-content-type '("javascript" "jsx"))
      (setq-local comment-start "//")
      (setq-local comment-end "")
      (setq-local comment-start-skip "// *")))
  (add-hook 'web-mode-hook #'+web--fix-js-comments-h)

  (general-define-key
   :keymaps 'web-mode-map
   :states '(normal visual emacs)
   :prefix doom-localleader-key
   "h" '(web-mode-reload :wk "rehighlight buffer")
   "i" '(web-mode-buffer-indent :wk "indent buffer")
   "ab" '(web-mode-attribute-beginning :wk "attribute beginning")
   "ae" '(web-mode-attribute-end :wk "attribute end")
   "ai" '(web-mode-attribute-insert :wk "attribute insert")
   "an" '(web-mode-attribute-next :wk "attribute next")
   "as" '(web-mode-attribute-select :wk "attribute select")
   "ak" '(web-mode-attribute-kill :wk "attribute kill")
   "ap" '(web-mode-attribute-previous :wk "attribute previous")
   "at" '(web-mode-attribute-transpose :wk "attribute transpose")
   "bb" '(web-mode-block-beginning :wk "block beginning")
   "bc" '(web-mode-block-close :wk "block close")
   "be" '(web-mode-block-end :wk "block end")
   "bk" '(web-mode-block-kill :wk "block kill")
   "bn" '(web-mode-block-next :wk "block next")
   "bp" '(web-mode-block-previous :wk "block previous")
   "bs" '(web-mode-block-select :wk "block select")
   "da" '(web-mode-dom-apostrophes-replace :wk "dom apostrophes replace")
   "dd" '(web-mode-dom-errors-show :wk "dom errors show")
   "de" '(web-mode-dom-entities-encode :wk "dom entities encode")
   "dn" '(web-mode-dom-normalize :wk "dom normalize")
   "dq" '(web-mode-dom-quotes-replace :wk "dom quotes replace")
   "dt" '(web-mode-dom-traverse :wk "dom traverse")
   "dx" '(web-mode-dom-xpath :wk "dom xpath")
   "e/" '(web-mode-element-close :wk "element close")
   "ea" '(web-mode-element-content-select :wk "element content select")
   "eb" '(web-mode-element-beginning :wk "element beginning")
   "ec" '(web-mode-element-clone :wk "element clone")
   "ed" '(web-mode-element-child :wk "element child")
   "ee" '(web-mode-element-end :wk "element end")
   "ef" '(web-mode-element-children-fold-or-unfold :wk "element fold/unfold")
   "ei" '(web-mode-element-insert :wk "element insert")
   "ek" '(web-mode-element-kill :wk "element kill")
   "em" '(web-mode-element-mute-blanks :wk "element mute blanks")
   "en" '(web-mode-element-next :wk "element next")
   "ep" '(web-mode-element-previous :wk "element previous")
   "er" '(web-mode-element-rename :wk "element rename")
   "es" '(web-mode-element-select :wk "element select")
   "et" '(web-mode-element-transpose :wk "element transpose")
   "eu" '(web-mode-element-parent :wk "element parent")
   "ev" '(web-mode-element-vanish :wk "element vanish")
   "ew" '(web-mode-element-wrap :wk "element wrap")
   "ta" '(web-mode-tag-attributes-sort :wk "tag attributes sort")
   "tb" '(web-mode-tag-beginning :wk "tag beginning")
   "te" '(web-mode-tag-end :wk "tag end")
   "tm" '(web-mode-tag-match :wk "tag match")
   "tn" '(web-mode-tag-next :wk "tag next")
   "tp" '(web-mode-tag-previous :wk "tag previous")
   "ts" '(web-mode-tag-select :wk "tag select"))

  (general-define-key
   :keymaps 'web-mode-map
   :states '(insert)
   "SPC" #'self-insert-command)
  (general-define-key
   :keymaps 'web-mode-map
   :states '(normal)
   "za" #'web-mode-fold-or-unfold)
  (general-define-key
   :keymaps 'web-mode-map
   :states '(normal visual)
   "]a" #'web-mode-attribute-next
   "[a" #'web-mode-attribute-previous
   "]t" #'web-mode-tag-next
   "[t" #'web-mode-tag-previous
   "]T" #'web-mode-element-child
   "[T" #'web-mode-element-parent))

(when (modulep! +lsp)
  (add-hook 'html-mode-hook #'lsp-deferred)
  (add-hook 'html-ts-mode-hook #'lsp-deferred)
  (add-hook 'web-mode-hook #'lsp-deferred)
  (add-hook 'nxml-mode-hook #'lsp-deferred))

;;; -- web +css ---------------------------------------------------------------

(defvar +web-continue-block-comments t
  "If non-nil, newlines in block comments are continued with a leading *.

This also indirectly means the asterisks in the opening /* and closing */ will
be aligned.

If set to `nil', disable all the above behaviors.")

(add-to-list 'find-sibling-rules '("/\\([^/]+\\)\\.\\(\\(s[ac]\\|le\\)ss\\|styl\\)\\'" "\\1\\.css\\'"))
(add-to-list 'find-sibling-rules '("/\\([^/]+\\)\\.css\\'" "\\1\\.\\(\\(s[ac]\\|le\\)ss\\|styl\\)\\'"))

;; Correctly continue /* and // comments on newline-and-indent
(add-hook 'css-mode-hook
          (lambda ()
            (setq-local comment-line-break-function #'+css/comment-indent-new-line)
            (setq-local adaptive-fill-function #'+css-adaptive-fill-fn)
            (setq-local adaptive-fill-first-line-regexp "\\'[ \t]*\\(?:\\* *\\)?\\'")))

(add-hook 'css-mode-hook #'rainbow-mode)
(add-hook 'sass-mode-hook #'rainbow-mode)
(add-hook 'stylus-mode-hook #'rainbow-mode)

(with-eval-after-load 'css-mode
  (general-define-key
   :keymaps '(css-mode-map scss-mode-map less-css-mode-map)
   :states '(normal visual emacs)
   :prefix doom-localleader-key
   "rb" '(#'+css/toggle-inline-or-block :wk "toggle inline/block")))

(when (modulep! +lsp)
  (add-hook 'css-mode-hook #'lsp-deferred)
  (add-hook 'css-ts-mode-hook #'lsp-deferred)
  (add-hook 'scss-mode-hook #'lsp-deferred)
  (add-hook 'sass-mode-hook #'lsp-deferred)
  (add-hook 'less-css-mode-hook #'lsp-deferred))

(leaf rainbow-mode
  :ensure t
  :defer t)

(leaf sass-mode
  :ensure t
  :defer t)

;;; -- web helpers (autoload/html.el, autoload/css.el) -------------------------

(defun +web/indent-or-yas-or-emmet-expand ()
  "Do-what-I-mean on TAB.

Invokes `indent-for-tab-command' if at or before text bol, `yas-expand' if on a
snippet, or `emmet-expand-yas'/`emmet-expand-line', depending on whether
`yas-minor-mode' is enabled or not."
  (interactive)
  (call-interactively
   (cond ((or (<= (current-column) (current-indentation))
              (not (eolp))
              (not (or (memq (char-after) (list ?\n ?\s ?\t))
                       (eobp))))
          #'indent-for-tab-command)
         ((modulep! :editor snippets)
          (require 'yasnippet)
          (if (yas--templates-for-key-at-point)
              #'yas-expand
            #'emmet-expand-yas))
         (#'emmet-expand-line))))

(defun +css--toggle-inline-or-block (beg end)
  (skip-chars-forward " \t")
  (let ((orig (point-marker)))
    (goto-char beg)
    (if (= (line-number-at-pos beg) (line-number-at-pos end))
        (progn
          (forward-char)
          (insert "\n")
          (while (re-search-forward ";\\s-+" end t)
            (replace-match ";\n" nil t))
          (indent-region beg end))
      (save-excursion
        (while (re-search-forward "\n+" end t)
          (replace-match " " nil t)))
      (while (re-search-forward "\\([{;]\\) +" end t)
        (replace-match (concat (match-string 1) " ") nil t)))
    (if orig (goto-char orig))
    (skip-chars-forward " \t")))

(defun +css/toggle-inline-or-block ()
  "Toggles between a bracketed block and inline block."
  (interactive)
  (let ((inhibit-modification-hooks t))
    (cl-destructuring-bind (&key beg end op cl &allow-other-keys)
        (save-excursion
          (when (and (eq (char-after) ?\{)
                     (not (eq (char-before) ?\{)))
            (forward-char))
          (sp-get-sexp))
      (when (or (not (and beg end op cl))
                (string-empty-p op) (string-empty-p cl))
        (user-error "No block found %s" (list beg end op cl)))
      (unless (string= op "{")
        (user-error "Incorrect block found"))
      (+css--toggle-inline-or-block beg end))))

(defun +css/comment-indent-new-line (&optional _)
  "Continues the comment in an indented new line.

Meant for `comment-line-break-function' in `css-mode' and `scss-mode'."
  (interactive)
  (cond ((or (not (doom-point-in-comment-p))
             (and comment-use-syntax
                  (not (save-excursion (comment-beginning)))))
         (let (comment-line-break-function)
           (newline-and-indent)))

        ((save-match-data
           (let ((at-end (looking-at-p ".+\\*/"))
                 (indent-char (if indent-tabs-mode ?\t ?\s))
                 (post-indent (save-excursion
                                (move-to-column (1+ (current-indentation)))
                                (skip-chars-forward " \t" (line-end-position))))
                 (pre-indent (current-indentation))
                 opener)
             (save-excursion
               (if comment-use-syntax
                   (goto-char (comment-beginning))
                 (goto-char (line-beginning-position))
                 (when (re-search-forward comment-start-skip (line-end-position) t)
                   (goto-char (or (match-end 1)
                                  (match-beginning 0)))))
               (if (looking-at "\\(//\\|/?\\*\\**/?\\)\\(?:[^/]\\)")
                   (setq opener (match-string-no-properties 1)
                         pre-indent (- (match-beginning 1) (line-beginning-position)))
                 (setq opener ""
                       pre-indent 0)))
             (insert-and-inherit
              "\n" (make-string pre-indent indent-char)
              (if (string-prefix-p "/*" opener)
                  (if (or (eq +web-continue-block-comments t)
                          (string= "/**" opener))
                      " *"
                    "")
                opener)
              (make-string post-indent indent-char))
             (when at-end
               (save-excursion
                 (just-one-space)
                 (insert "\n" (make-string pre-indent indent-char)))))))))

(defun +css-adaptive-fill-fn ()
  "An `adaptive-fill-function' that conjoins SCSS line comments correctly."
  (when (looking-at "[ \t]*/[/*][ \t]*")
    (let ((str (match-string 0)))
      (when (string-match "/[/*]" str)
        (replace-match (if (string= (match-string 0 str) "/*")
                           " *"
                         "//")
                       t t str)))))

;;; ===================================================================
;;; Packages dropped during the port (no nixpkgs package / dead flag):
;;;   - nose (python test runner; not in nixpkgs)
;;;   - pyenv-mode, uv-mode, conda, poetry, lsp-pyright (+pyenv/+uv/+conda/
;;;     +poetry/+pyright flags disabled)
;;;   - cython-mode, flycheck-cython (+cython disabled)
;;;   - flycheck-package, package-lint-flymake (:checkers syntax uses neither
;;;     the -flymake nor +flymake flag in this config)
;;;   - company-shell, bash-completion (:completion company disabled / +lsp
;;;     enabled)
;;;   - counsel-jq, helm-nixos-options, counsel-css, helm-css-scss (ivy/helm
;;;     completion disabled)
;;;   - ccls (+lsp but :tools lsp -eglot false)
;;;   - markdown-ts-mode, html-ts-mode, mhtml-ts-mode, css-ts-mode,
;;;     yaml-ts-mode, json-ts-mode, go-work/ts treesitter remaps
;;;     (set-tree-sitter! has no port; builtin ts modes not wired)
;;;   - ox-rst (:lang rst not ported), org-contrib, ob-go, org-roam,
;;;     org-download, org-journal, org-noter, org-modern, org-appear,
;;;     org-tree-slide, centered-window (org +flags disabled)
;;;   - evil-org's cl-defmethod for rust-analyzer signatures (requires dash/s,
;;;     only under -eglot)
;;;   - the org popup rules (set-popup-rules! has no port)

;;; lang-config.el ends here
(provide 'lang-config)
