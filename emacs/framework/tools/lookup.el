;;; tools/lookup.el --- doom tools/lookup port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/tools/lookup. Uses the lunatix-doom compat layer.
;;; Code:

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
  (luna-log "Looking up '%s' with '%s'" identifier handler)
  (condition-case-unless-debug e
      (let ((wconf (current-window-configuration))
            (result (condition-case-unless-debug e
                        (+lookup--run-handler handler identifier)
                      (error
                       (luna-log "Lookup handler %S threw an error: %s" handler e)
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
               ((luna-region-active-p)
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
                  (when (file-in-directory-p dir (luna-project-root))
                    (find-file (expand-file-name guess dir))
                    t))))
          ((and (modulep! :completion vertico)
                (doom-project-p)
                (fboundp '+vertico/consult-fd-or-find))
           (+vertico/consult-fd-or-find (luna-project-root) guess))
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
  :commands dumb-jump-result-follow
  :config
  (setq dumb-jump-default-project (luna-user-dir)
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
(after! xref
  (leaf consult-xref
    :ensure nil
    :defer t
    :init
    (setq xref-show-xrefs-function       #'consult-xref
          xref-show-definitions-function #'consult-xref)))

;; Dash docset integration (`+docsets') and dictionary packages (`+dictionary')
;; are not enabled; their configs are dropped.

;;
;;; tools/lsp (lsp-mode + lsp-ui; eglot variant not enabled)

;; GC magic hacker — +lsp-optimization-mode and doom's lsp GC tuning need it
(leaf gcmh
  :ensure t
  :demand t
  :config
  (gcmh-mode 1))

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

;;; tools/lookup.el ends here
