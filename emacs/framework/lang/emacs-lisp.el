;;; lang/emacs-lisp.el --- doom lang/emacs-lisp port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/emacs-lisp.
;;; Code:

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
   :states '(normal visual motion)
   :prefix luna-localleader-key
   "b" '(#'+emacs-lisp/change-working-buffer :wk "Set working buffer")
   "m" '(macrostep-expand :wk "Expand macro"))
  (general-define-key
   :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " d")
   "f" '(#'+emacs-lisp/edebug-instrument-defun-on :wk "debug defun on")
   "F" '(#'+emacs-lisp/edebug-instrument-defun-off :wk "debug defun off"))
  (general-define-key
   :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " e")
   "b" '(eval-buffer :wk "eval buffer")
   "d" '(eval-defun :wk "eval defun")
   "e" '(eval-last-sexp :wk "eval last sexp")
   "r" '(eval-region :wk "eval region")
   "l" '(load-library :wk "load library"))
  (general-define-key
   :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " g")
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
  (add-to-list 'elisp-demos-user-files (expand-file-name "demos.org" (luna-user-dir)))
  (defun +emacs-lisp--optimize-org-init-a (fn &rest args)
    "Disable unrelated functionality to optimize calls to `org-mode'."
    (dlet ((org-inhibit-startup t)
           (luna-inhibit-local-var-hooks t)
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
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " t")
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
  (defun luna-use-helpful-a (fn &rest args)
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
  (advice-add #'org-link--open-help :around #'luna-use-helpful-a)
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
         (append (list default-directory (or (luna-project-root)
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
  (let ((default-directory (luna-project-root)))
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
                                 (setq unaliased (advice--cd*r unaliased))
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

(defvar +org-preview-dir (expand-file-name "org/previews/" (luna-profile-cache-dir))
  "Where link preview images are cached.")

(defvar +org-startup-with-animated-gifs nil
  "If non-nil, and the cursor is over a gif inline-image preview, animate it.")

;;; lang/emacs-lisp.el ends here