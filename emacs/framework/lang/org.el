;;; lang/org.el --- doom lang/org port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/org.
;;; Code:

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
                 (dlet ((luna-inhibit-local-var-hooks t))
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
    (remove-hook 'luna-switch-buffer-hook #'+org--restart-mode-h 'local)
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
      (when (memq #'+org--restart-mode-h luna-switch-buffer-hook)
        (+org--restart-mode-h))))
  (advice-add #'org-capture-get-indirect-buffer :before #'+org--restart-mode-before-indirect-buffer-a)

  (defun +org--optimize-backgrounded-agenda-buffers-a (fn file)
    "Disable `org-mode's startup processes for temporary agenda buffers."
    (if-let* ((buf (org-find-base-buffer-visiting file)))
        buf
      (dlet ((recentf-exclude '(always))
             (luna-inhibit-local-var-hooks t)
             (org-inhibit-startup t)
             so-long-target-modes
             vc-handled-backends
             enable-local-variables
             find-file-hook)
        (when-let* ((buf (delay-mode-hooks (funcall fn file))))
          (with-current-buffer buf
            (add-hook 'luna-switch-buffer-hook #'+org--restart-mode-h
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
  (add-hook 'luna-escape-hook #'+org-remove-occur-highlights-h)

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
   :states '(normal visual motion)
   :prefix luna-localleader-key
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
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " a")
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
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " b")
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
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " c")
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
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " d")
   "d" '(org-deadline :wk "deadline")
   "s" '(org-schedule :wk "schedule")
   "t" '(org-time-stamp :wk "time stamp")
   "T" '(org-time-stamp-inactive :wk "inactive time stamp"))

  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " g")
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
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " l")
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
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " P")
   "a" '(org-publish-all :wk "publish all")
   "f" '(org-publish-current-file :wk "publish current file")
   "p" '(org-publish :wk "publish")
   "P" '(org-publish-current-project :wk "publish current project")
   "s" '(org-publish-sitemap :wk "publish sitemap"))

  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " r")
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
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " s")
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
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " p")
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
     :states '(normal visual motion)
     :prefix luna-localleader-key
     "q" '(org-agenda-set-tags :wk "set tags")
     "r" '(org-agenda-refile :wk "refile")
     "t" '(org-agenda-todo :wk "todo"))
    (general-define-key
     :keymaps 'org-agenda-mode-map
     :states '(normal visual motion)
     :prefix (concat luna-localleader-key " d")
     "d" '(org-agenda-deadline :wk "deadline")
     "s" '(org-agenda-schedule :wk "schedule"))
    (general-define-key
     :keymaps 'org-agenda-mode-map
     :states '(normal visual motion)
     :prefix (concat luna-localleader-key " c")
     "c" '(org-agenda-clock-cancel :wk "clock cancel")
     "g" '(org-agenda-clock-goto :wk "clock goto")
     "i" '(org-agenda-clock-in :wk "clock in")
     "o" '(org-agenda-clock-out :wk "clock out")
     "r" '(org-agenda-clockreport-mode :wk "clock report mode")
     "s" '(org-agenda-show-clocking-issues :wk "clocking issues"))
    (general-define-key
     :keymaps 'org-agenda-mode-map
     :states '(normal visual motion)
     :prefix (concat luna-localleader-key " p")
     "d" '(org-agenda-priority-down :wk "priority down")
     "p" '(org-agenda-priority :wk "priority")
     "u" '(org-agenda-priority-up :wk "priority up"))))

(defun +org-init-popup-rules-h ()
  ;; Doom's `set-popup-rules!' has no port here (window rules for org buffers
  ;; are left to the window manager); dropped.
  nil)


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
  (setq org-clock-persist-file (expand-file-name "org-clock-save.el" (luna-profile-data-dir)))
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
  (when (boundp 'evil-org-agenda-mode-map)
    (evil-define-key* 'motion evil-org-agenda-mode-map
      (kbd luna-leader-key) nil)))

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

  (setq org-persist-directory (expand-file-name "org/persist/" (luna-profile-cache-dir))
        org-publish-timestamp-directory (expand-file-name "org/timestamps/" (luna-profile-cache-dir))
        org-preview-latex-image-directory (expand-file-name "org/latex/" (luna-profile-cache-dir))
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
    (cond ((luna-region-active-p)
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
         (unless (luna-temp-buffer-p buf)
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
         (luna-project-root)
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
   (directory-file-name (or (luna-project-root) default-directory))))

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

;;; lang/org.el ends here