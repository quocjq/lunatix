;;; ui/workspaces.el --- doom ui/workspaces port  -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/workspaces.
;;; no-byte-compile: byte/native-compiling this file hangs this laptop's native
;;; compiler; loaded from source instead (doom also loads configs interpreted).
;;; Code:

;;; :ui workspaces
(defvar +workspaces-main "main"
  "The name of the primary and initial workspace, which cannot be deleted.")

(defvar +workspaces-switch-project-function #'projectile-switch-project
  "The function to run after switching to a new project. It must take one
argument: the new project directory. (APROX: doom defaulted to doom's own
`doom-project-find-file'.)")

(defvar +workspaces-on-switch-project-behavior 'non-empty
  "Controls the behavior of workspaces when switching to a new project.

Can be one of the following:

t           Always create a new workspace for the project
'non-empty  Only create a new workspace if the current one already has buffers
            associated with it.
nil         Never create a new workspace on project switch.")

(defvar +workspaces-data-file "_workspaces"
  "The basename of the file to store single workspace perspectives. Will be
stored in `persp-save-dir'.")

(defvar +workspace--old-uniquify-style nil)

;;; +workspace* library (ui/workspaces/autoload/workspaces.el)
(defvar +workspace--last nil)
(defvar +workspace--index 0)

(defface +workspace-tab-selected-face '((t (:inherit highlight)))
  "The face for selected tabs displayed by `+workspace/display'"
  :group 'persp-mode)

(defface +workspace-tab-face '((t (:inherit default)))
  "The face for tabs displayed by `+workspace/display'"
  :group 'persp-mode)

;;; Library
(defun +workspace--protected-p (name)
  (equal name persp-nil-name))

(defun +workspace--generate-id ()
  (or (cl-loop for name in (+workspace-list-names)
               when (string-match-p "^#[0-9]+$" name)
               maximize (string-to-number (substring name 1)) into max
               finally return (if max (1+ max)))
      1))

;;; Predicates
(defalias #'+workspace-p #'perspective-p
  "Return t if OBJ is a perspective hash table.")

(defun +workspace-exists-p (name)
  "Returns t if NAME is the name of an existing workspace."
  (member name (+workspace-list-names)))

(defalias #'+workspace-contains-buffer-p #'persp-contain-buffer-p
  "Return non-nil if BUFFER is in WORKSPACE (defaults to current workspace).")

;;; Getters
(defalias #'+workspace-current #'get-current-persp
  "Return the currently active workspace.")

(defun +workspace-get (name &optional noerror)
  "Return a workspace named NAME. Unless NOERROR is non-nil, this throws an
error if NAME doesn't exist."
  (cl-check-type name string)
  (when-let* ((persp (persp-get-by-name name)))
    (cond ((+workspace-p persp) persp)
          ((not noerror)
           (error "No workspace called '%s' was found" name)))))

(defun +workspace-current-name ()
  "Get the name of the current workspace."
  (safe-persp-name (+workspace-current)))

(defun +workspace-list-names ()
  "Return the list of names of open workspaces."
  (cl-remove persp-nil-name persp-names-cache :count 1))

(defun +workspace-list ()
  "Return a list of workspace structs (satisfies `+workspace-p')."
  (cl-loop for name in (+workspace-list-names)
           if (gethash name *persp-hash*)
           collect it))

(defun +workspace-buffer-list (&optional persp)
  "Return a list of buffers in PERSP.

PERSP can be a string (name of a workspace) or a workspace (satisfies
`+workspace-p'). If nil or omitted, it defaults to the current workspace."
  (let ((persp (or persp (+workspace-current))))
    (unless (+workspace-p persp)
      (user-error "Not in a valid workspace (%s)" persp))
    (persp-buffers persp)))

(defun +workspace-orphaned-buffer-list ()
  "Return a list of buffers that aren't associated with any perspective."
  (cl-remove-if #'persp--buffer-in-persps (buffer-list)))

;;; Actions
(defun +workspace-load (name)
  "Loads a single workspace (named NAME) into the current session. Can only
retrieve perspectives that were explicitly saved with `+workspace-save'.

Returns t if successful, nil otherwise."
  (when (+workspace-exists-p name)
    (user-error "A workspace named '%s' already exists." name))
  (persp-load-from-file-by-names
   (expand-file-name +workspaces-data-file persp-save-dir)
   *persp-hash* (list name))
  (+workspace-exists-p name))

(defun +workspace-save (name)
  "Saves a single workspace (NAME) from the current session. Can be loaded again
with `+workspace-load'. NAME can be the string name of a workspace or its
perspective hash table.

Returns t on success, nil otherwise."
  (unless (+workspace-exists-p name)
    (error "'%s' is an invalid workspace" name))
  (let ((fname (expand-file-name +workspaces-data-file persp-save-dir)))
    (persp-save-to-file-by-names fname *persp-hash* (list name) t)
    (and (member name (persp-list-persp-names-in-file fname))
         t)))

(defun +workspace-delete (workspace)
  "Delete WORKSPACE from the saved workspaces in `persp-save-dir'.

Return t if WORKSPACE was successfully deleted. Throws error if WORKSPACE is not
found or wasn't saved with `+workspace-save'. APROX: doom used `doom-file-read'/
`doom-file-write'; inlined with vanilla read/print."
  (let* ((fname (expand-file-name +workspaces-data-file persp-save-dir))
         (workspace-name (if (stringp workspace) workspace (persp-name workspace)))
         (workspace-names (persp-list-persp-names-in-file fname))
         (workspace-idx (cl-position workspace-name workspace-names :test #'equal)))
    (unless workspace-idx
      (error "Couldn't find saved workspace '%s'" workspace-name))
    (let ((savelist (with-temp-buffer
                      (insert-file-contents fname)
                      (goto-char (point-min))
                      (read (buffer-string)))))
      (with-temp-file fname
        (prin1 (cl-remove-if (lambda (ws) (equal workspace-name (nth 1 ws)))
                             savelist :count 1)
               (current-buffer))))
    (not (member workspace-name (persp-list-persp-names-in-file fname)))))

(defun +workspace-new (name)
  "Create a new workspace named NAME. If one already exists, return nil.
Otherwise return t on success, nil otherwise."
  (when (+workspace--protected-p name)
    (error "Can't create a new '%s' workspace" name))
  (when (+workspace-exists-p name)
    (error "A workspace named '%s' already exists" name))
  (let ((persp (persp-add-new name)))
    (save-window-excursion
      (let ((ignore-window-parameters t))
        (persp-delete-other-windows))
      (switch-to-buffer (luna-fallback-buffer))
      (setf (persp-window-conf persp)
            (funcall persp-window-state-get-function (selected-frame))))
    persp))

(defun +workspace-rename (name new-name)
  "Rename the current workspace named NAME to NEW-NAME. Returns old name on
success, nil otherwise."
  (when (+workspace--protected-p name)
    (error "Can't rename '%s' workspace" name))
  (persp-rename new-name (+workspace-get name)))

(defun +workspace-kill (workspace &optional inhibit-kill-p)
  "Kill the workspace denoted by WORKSPACE, which can be the name of a
perspective or its hash table. If INHIBIT-KILL-P is non-nil, don't kill this
workspace's buffers."
  (unless (stringp workspace)
    (setq workspace (persp-name workspace)))
  (when (+workspace--protected-p workspace)
    (error "Can't delete '%s' workspace" workspace))
  (+workspace-get workspace) ; error checking
  (persp-kill workspace inhibit-kill-p)
  (not (+workspace-exists-p workspace)))

(defun +workspace-switch (name &optional auto-create-p)
  "Switch to another workspace named NAME (a string).

If AUTO-CREATE-P is non-nil, create the workspace if it doesn't exist, otherwise
throws an error."
  (unless (+workspace-exists-p name)
    (if auto-create-p
        (+workspace-new name)
      (error "%s is not an available workspace" name)))
  (let ((old-name (+workspace-current-name)))
    (unless (equal old-name name)
      (setq +workspace--last
            (or (and (not (+workspace--protected-p old-name))
                     old-name)
                +workspaces-main))
      (persp-frame-switch name))
    (equal (+workspace-current-name) name)))

;;; Commands
(defun +workspace/restore-last-session ()
  "Restore the last autosaved session, if one exists."
  (interactive)
  (let ((fname (expand-file-name persp-auto-save-fname persp-save-dir)))
    (if (file-exists-p fname)
        (persp-load-state-from-file fname)
      (+workspace-error "No autosaved session found"))))

(defun +workspace/load (name)
  "Load a workspace and switch to it. If called with C-u, try to reload the
current workspace (by name) from session files."
  (interactive
   (list
    (if current-prefix-arg
        (+workspace-current-name)
      (completing-read
       "Workspace to load: "
       (persp-list-persp-names-in-file
        (expand-file-name +workspaces-data-file persp-save-dir))))))
  (if (not (+workspace-load name))
      (+workspace-error (format "Couldn't load workspace %s" name))
    (+workspace/switch-to name)
    (+workspace/display)))

(defun +workspace/save (name)
  "Save the current workspace. If called with C-u, autosave the current
workspace."
  (interactive
   (list
    (if current-prefix-arg
        (+workspace-current-name)
      (completing-read "Workspace to save: " (+workspace-list-names)))))
  (if (+workspace-save name)
      (+workspace-message (format "'%s' workspace saved" name) 'success)
    (+workspace-error (format "Couldn't save workspace %s" name))))

(defun +workspace/rename (new-name)
  "Rename the current workspace."
  (interactive (list (completing-read "New workspace name: " (list (+workspace-current-name)))))
  (condition-case ex
      (let* ((current-name (+workspace-current-name))
             (old-name (+workspace-rename current-name new-name)))
        (unless old-name
          (error "Failed to rename %s" current-name))
        (+workspace-message (format "Renamed '%s'->'%s'" old-name new-name) 'success))
    ('error (+workspace-error ex t))))

(defun +workspace/kill (name)
  "Delete this workspace. If called with C-u, prompts you for the name of the
workspace to delete."
  (interactive
   (let ((current-name (+workspace-current-name)))
     (list
      (if current-prefix-arg
          (completing-read (format "Kill workspace (default: %s): " current-name)
                           (+workspace-list-names)
                           nil nil nil nil current-name)
        current-name))))
  (condition-case ex
      (let ((workspaces (+workspace-list-names)))
        (if (not (member name workspaces))
            (+workspace-message (format "'%s' workspace doesn't exist" name) 'warn)
          (cond ((delq (selected-frame) (persp-frames-with-persp (get-frame-persp)))
                 (user-error "Can't close workspace, it's visible in another frame"))
                ((not (equal (+workspace-current-name) name))
                 (+workspace-kill name))
                ((cdr workspaces)
                 (+workspace-kill name)
                 (+workspace-switch
                  (if (+workspace-exists-p +workspace--last)
                      +workspace--last
                    (car (+workspace-list-names))))
                 ;; APROX: doom used `doom-buffer-frame-predicate'; use
                 ;; `get-buffer-window'.
                 (unless (get-buffer-window (window-buffer) 0 t)
                   (switch-to-buffer (luna-fallback-buffer))))
                (t
                 (+workspace-switch +workspaces-main t)
                 (unless (string= (car workspaces) +workspaces-main)
                   (+workspace-kill name))
                 (+workspaces-kill-buffers
                  (cl-remove-if-not #'luna-real-buffer-p (buffer-list)))))
          (+workspace-message (format "Deleted '%s' workspace" name) 'success)))
    ('error (+workspace-error ex t))))

(defun +workspace/delete (name)
  "Delete a saved workspace in `persp-save-dir'.

Can only delete workspaces saved with `+workspace/save' or `+workspace-save'."
  (interactive
   (list
    (completing-read "Delete saved workspace: "
                     (cl-loop with wsfile = (expand-file-name +workspaces-data-file persp-save-dir)
                              for p in (persp-list-persp-names-in-file wsfile)
                              collect p))))
  (and (condition-case ex
           (or (+workspace-delete name)
               (+workspace-error (format "Couldn't delete '%s' workspace" name)))
         ('error (+workspace-error ex t)))
       (+workspace-message (format "Deleted '%s' workspace" name) 'success)))

(defun +workspace/kill-session (&optional interactive)
  "Delete the current session, all workspaces, windows and their buffers."
  (interactive (list t))
  (let ((windows (length (window-list)))
        (persps (length (+workspace-list-names)))
        (buffers 0))
    (let ((persp-autokill-buffer-on-remove t))
      (unless (cl-every #'+workspace-kill (+workspace-list-names))
        (+workspace-error "Could not clear session")))
    (+workspace-switch +workspaces-main t)
    (setq buffers (+workspaces-kill-buffers (buffer-list)))
    (when interactive
      (message "Killed %d workspace(s), %d window(s) & %d buffer(s)"
               persps windows buffers))))

(defun +workspace/kill-session-and-quit ()
  "Kill emacs without saving anything."
  (interactive)
  (let ((persp-auto-save-opt 0))
    (kill-emacs)))

(defun +workspace/new (&optional name clone-p)
  "Create a new workspace named NAME. If CLONE-P is non-nil, clone the current
workspace, otherwise the new workspace is blank."
  (interactive (list nil current-prefix-arg))
  (unless name
    (setq name (format "#%s" (+workspace--generate-id))))
  (condition-case e
      (cond ((+workspace-exists-p name)
             (error "%s already exists" name))
            (clone-p (persp-copy name t))
            (t
             (+workspace-switch name t)
             (+workspace/display)))
    ((debug error) (+workspace-error (cadr e) t))))

(defun +workspace/new-named (name)
  "Create a new workspace with a given NAME."
  (interactive "sWorkspace Name: ")
  (+workspace/new name))

(defun +workspace/switch-to (index)
  "Switch to a workspace at a given INDEX. A negative number will start from the
end of the workspace list."
  (interactive
   (list (or current-prefix-arg
             (completing-read "Switch to workspace: " (+workspace-list-names)))))
  (when (and (stringp index)
             (string-match-p "^[0-9]+$" index))
    (setq index (string-to-number index)))
  (condition-case ex
      (let ((names (+workspace-list-names))
            (old-name (+workspace-current-name)))
        (cond ((numberp index)
               (let ((dest (nth index names)))
                 (unless dest
                   (error "No workspace at #%s" (1+ index)))
                 (+workspace-switch dest)))
              ((stringp index)
               (+workspace-switch index t))
              (t
               (error "Not a valid index: %s" index)))
        (unless (called-interactively-p 'interactive)
          (if (equal (+workspace-current-name) old-name)
              (+workspace-message (format "Already in %s" old-name) 'warn)
            (+workspace/display))))
    ('error (+workspace-error (cadr ex) t))))

(dotimes (i 9)
  (defalias (intern (format "+workspace/switch-to-%d" i))
    (lambda () (interactive) (+workspace/switch-to i))
    (format "Switch to workspace #%d" (1+ i))))

(defun +workspace/switch-to-final ()
  "Switch to the final workspace in open workspaces."
  (interactive)
  (+workspace/switch-to (car (last (+workspace-list-names)))))

(defun +workspace/other ()
  "Switch to the last activated workspace."
  (interactive)
  (+workspace/switch-to +workspace--last))

(defun +workspace/cycle (n)
  "Cycle n workspaces to the right (default) or left."
  (interactive (list 1))
  (let ((current-name (+workspace-current-name)))
    (if (+workspace--protected-p current-name)
        (+workspace-switch +workspaces-main t)
      (condition-case ex
          (let* ((persps (+workspace-list-names))
                 (perspc (length persps))
                 (index (cl-position current-name persps)))
            (when (= perspc 1)
              (user-error "No other workspaces"))
            (+workspace/switch-to (% (+ index n perspc) perspc))
            (unless (called-interactively-p 'interactive)
              (+workspace/display)))
        ('user-error (+workspace-error (cadr ex) t))
        ('error (+workspace-error ex t))))))

(defun +workspace/switch-left (&optional n)  (interactive "p") (+workspace/cycle (- n)))

(defun +workspace/switch-right (&optional n) (interactive "p") (+workspace/cycle n))

(defun +workspace/close-window-or-workspace ()
  "Close the selected window. If it's the last window in the workspace, either
close the workspace (as well as its associated frame, if one exists) and move to
the next."
  (interactive)
  (let ((delete-window-fn (if (featurep 'evil) #'evil-window-delete #'delete-window)))
    (if (window-dedicated-p)
        (funcall delete-window-fn)
      (let ((current-persp-name (+workspace-current-name)))
        (cond ((or (+workspace--protected-p current-persp-name)
                   ;; APROX: doom used `doom-visible-windows'; use `window-list'.
                   (cdr (window-list)))
               (funcall delete-window-fn))
              ((cdr (+workspace-list-names))
               (let ((frame-persp (frame-parameter nil 'workspace)))
                 (if (string= frame-persp (+workspace-current-name))
                     (delete-frame)
                   (+workspace/kill current-persp-name))))
              ((+workspace-error "Can't delete last workspace" t)))))))

(defun +workspace/swap-left (&optional count)
  "Swap the current workspace with the COUNTth workspace on its left."
  (interactive "p")
  (let* ((current-name (+workspace-current-name))
         (count (or count 1))
         (persps (+workspace-list-names))
         (index (- (cl-position current-name persps :test #'equal)
                   count))
         (names (remove current-name persps)))
    (unless names
      (user-error "Only one workspace"))
    (let ((index (min (max 0 index) (length names))))
      (setq persp-names-cache
            (append (cl-subseq names 0 index)
                    (list current-name)
                    (cl-subseq names index))))
    (when (called-interactively-p 'any)
      (+workspace/display))))

(defun +workspace/swap-right (&optional count)
  "Swap the current workspace with the COUNTth workspace on its right."
  (interactive "p")
  (funcall-interactively #'+workspace/swap-left (- count)))

;;; Tabs display in minibuffer
(defun +workspace--tabline (&optional names)
  (let ((names (or names (+workspace-list-names)))
        (current-name (+workspace-current-name)))
    (mapconcat
     #'identity
     (cl-loop for name in names
              for i to (length names)
              collect
              (propertize (format " [%d] %s " (1+ i) name)
                          'face (if (equal current-name name)
                                    '+workspace-tab-selected-face
                                  '+workspace-tab-face)))
     " ")))

(defun +workspace--message-body (message &optional type)
  (concat (+workspace--tabline)
          (propertize " | " 'face 'font-lock-comment-face)
          (propertize (format "%s" message)
                      'face (pcase type
                              ('error 'error)
                              ('warn 'warning)
                              ('success 'success)
                              ('info 'font-lock-comment-face)))))

(defun +workspace-message (message &optional type)
  "Show an 'elegant' message in the echo area next to a listing of workspaces."
  (message "%s" (+workspace--message-body message type)))

(defun +workspace-error (message &optional noerror)
  "Show an 'elegant' error in the echo area next to a listing of workspaces."
  (funcall (if noerror #'message #'error)
           "%s" (+workspace--message-body message 'error)))

(defun +workspace/display ()
  "Display a list of workspaces (like tabs) in the echo area."
  (interactive)
  (let (message-log-max)
    (message "%s" (+workspace--tabline))))

;;; Evil ex-commands (ui/workspaces/autoload/evil.el)
(after! evil
  (evil-define-command +workspace:save (&optional name)
    "Ex wrapper around `+workspace/save-session'."
    (interactive "<a>") (+workspace/save name))

  (evil-define-command +workspace:load (&optional name)
    "Ex wrapper around `+workspace/load-session'."
    (interactive "<a>") (+workspace/load name))

  (evil-define-command +workspace:new (bang name)
    "Ex wrapper around `+workspace/new'. If BANG, clone the current workspace."
    (interactive "<!><a>") (+workspace/new name bang))

  (evil-define-command +workspace:rename (new-name)
    "Ex wrapper around `+workspace/rename'."
    (interactive "<a>") (+workspace/rename new-name))

  (evil-define-command +workspace:delete ()
    "Ex wrapper around `+workspace/kill'."
    (interactive) (+workspace/kill (+workspace-current-name)))

  (evil-define-command +workspace:switch-next (&optional count)
    "Switch to next workspace. If COUNT, switch to COUNT-th workspace."
    (interactive "<c>")
    (if count (+workspace/switch-to count) (+workspace/cycle +1)))

  (evil-define-command +workspace:switch-previous (&optional count)
    "Switch to previous workspace. If COUNT, switch to COUNT-th workspace."
    (interactive "<c>")
    (if count (+workspace/switch-to count) (+workspace/cycle -1))))

;;; Hooks + helpers (from ui/workspaces/config.el and autoload/workspaces.el)
(defun +workspaces-ensure-no-nil-workspaces-h (&rest _)
  (when persp-mode
    (dolist (frame (frame-list))
      (when (string= (safe-persp-name (get-current-persp frame)) persp-nil-name)
        ;; Take extra steps to ensure no frame ends up in the nil perspective
        (persp-frame-switch (or (cadr (hash-table-keys *persp-hash*))
                                +workspaces-main)
                            frame)))))

(defun +workspaces-init-first-workspace-h (&rest _)
  "Ensure a main workspace exists."
  (when persp-mode
    (let (persp-before-switch-functions)
      (unless (or (persp-get-by-name +workspaces-main)
                  ;; Start from 2 b/c persp-mode counts the nil workspace
                  (> (hash-table-count *persp-hash*) 2))
        (persp-add-new +workspaces-main))
      ;; HACK: the warnings buffer gets swallowed when creating
      ;;   `+workspaces-main', so display it ourselves.
      (when-let* ((warnings (get-buffer "*Warnings*")))
        (unless (get-buffer-window warnings)
          (save-excursion
            (display-buffer-in-side-window
             warnings '((window-height . shrink-window-if-larger-than-buffer)))))))))

(defun +workspaces-init-persp-mode-h ()
  (cond (persp-mode
         ;; `uniquify' breaks persp-mode. It renames old buffers, which causes
         ;; errors when switching between perspectives (their buffers are
         ;; serialized by name and persp-mode expects them to have the same name
         ;; when restored).
         (when uniquify-buffer-name-style
           (setq +workspace--old-uniquify-style uniquify-buffer-name-style))
         (setq uniquify-buffer-name-style nil)
         ;; Ensure `persp-kill-buffer-query-function' is last
         (remove-hook 'kill-buffer-query-functions #'persp-kill-buffer-query-function)
         (add-hook 'kill-buffer-query-functions #'persp-kill-buffer-query-function t))
        (t
         (when +workspace--old-uniquify-style
           (setq uniquify-buffer-name-style +workspace--old-uniquify-style)))))
;; APROX: doom also advised `doom-buffer-list' to restrict it to the current
;; workspace; `doom-buffer-list' is doom-core (not ported), so the advice is
;; dropped.

;; Per-workspace `winner-mode' history
(defun +workspaces-save-winner-data-h (&rest _)
  (when (and (bound-and-true-p winner-mode)
             (get-current-persp))
    (set-persp-parameter
     'winner-ring (list winner-currents
                        winner-ring-alist
                        winner-pending-undo-ring))))

(defun +workspaces-load-winner-data-h (&rest _)
  (when (bound-and-true-p winner-mode)
    (cl-destructuring-bind
        (currents alist pending-undo-ring)
        (or (persp-parameter 'winner-ring) (list nil nil nil))
      (setq winner-undo-frame nil
            winner-currents currents
            winner-ring-alist alist
            winner-pending-undo-ring pending-undo-ring))))

;;; Registering buffers to perspectives
;; APROX: doom added this to `luna-switch-buffer-hook' (no-op here); hook the
;; real `window-buffer-change-functions' instead.
(defun +workspaces-add-current-buffer-h (&rest _)
  "Add current buffer to focused perspective."
  (or (not persp-mode)
      (persp-buffer-filtered-out-p
       (or (buffer-base-buffer (current-buffer))
           (current-buffer))
       persp-add-buffer-on-after-change-major-mode-filter-functions)
      (persp-add-buffer (current-buffer) (get-current-persp) nil nil)))

(defun +workspaces-unreal-buffer-p (buffer)
  "APROX: doom's `doom-unreal-buffer-p' (doom-core); temp buffers only."
  (luna-temp-buffer-p buffer))

;; Make `evil-alternate-buffer' ignore buffers outside the current workspace.
(after! evil
  (defadvice! +workspaces--evil-alternate-buffer-a (&optional window)
    :override #'evil-alternate-buffer
    (let* ((prev-buffers
            (if persp-mode
                (cl-remove-if-not #'persp-contain-buffer-p (window-prev-buffers)
                                  :key #'car)
              (window-prev-buffers)))
           (head (car prev-buffers)))
      (if (eq (car head) (window-buffer window))
          (cadr prev-buffers)
        head))))

;; Fix selecting deleted buffers when quitting Emacs or on some buffer listing
;; ops.
(defadvice! +workspaces-remove-dead-buffers-a (persp)
  :before #'persp-buffers-to-savelist
  (when (perspective-p persp)
    ;; HACK: Can't use `persp-buffers' because of a race condition with its gv
    ;;   getter/setter not being defined in time.
    (setf (aref persp 2)
          (cl-delete-if-not #'persp-get-buffer-or-null (persp-buffers persp)))))

;; Don't try to persist dead/remote buffers. They cause errors.
(defun +workspaces-dead-buffer-p (buf)
  "Ignore dead buffers in PERSP's buffer list."
  (not (buffer-live-p buf)))

(defun +workspaces-remote-buffer-p (buf)
  "And don't save TRAMP buffers; they're super slow to restore."
  (let ((dir (buffer-local-value 'default-directory buf)))
    (ignore-errors (file-remote-p dir))))

;; Per-frame workspaces
(defun +workspaces-delete-associated-workspace-h (&optional frame)
  "Delete workspace associated with current frame.
A workspace gets associated with a frame when a new frame is interactively
created."
  (when (and persp-mode (not (bound-and-true-p with-editor-mode)))
    (unless frame
      (setq frame (selected-frame)))
    (let ((frame-persp (frame-parameter frame 'workspace)))
      (when (string= frame-persp (+workspace-current-name))
        (+workspace/kill frame-persp)))))

(defun +workspaces-associate-frame-fn (frame &optional _new-frame-p)
  "Create a blank, new perspective and associate it with FRAME."
  (when persp-mode
    (with-selected-frame frame
      (if (not (cdr-safe (persp-frame-list-without-daemon)))
          (+workspace-switch +workspaces-main t)
        (+workspace-switch (format "#%s" (+workspace--generate-id)) t))
      (unless (luna-real-buffer-p (current-buffer))
        (let (switch-to-buffer-obey-display-actions) ; see #46
          (switch-to-buffer (luna-fallback-buffer))))
      (set-frame-parameter frame 'workspace (+workspace-current-name))
      ;; ensure every buffer has a buffer-predicate
      (persp-set-frame-buffer-predicate frame))
    (run-at-time 0.1 nil #'+workspace/display)))

;; Per-project workspaces, but reuse current workspace if empty
(defun +workspaces--project-name ()
  (let ((root (luna-project-root)))
    (file-name-nondirectory (directory-file-name (or root default-directory)))))

(defun +workspaces-switch-to-project-h (&optional dir)
  "Creates a workspace dedicated to a new project. If one already exists, switch
to it. If in the main workspace and it's empty, recycle that workspace, without
renaming it.

Afterwards, runs `+workspaces-switch-project-function'. By default, this prompts
the user to open a file in the new project."
  (let* ((default-directory (or dir default-directory))
         (pname (+workspaces--project-name))
         (proot (file-truename default-directory))
         ;; HACK: Clear projectile-project-root or cached roots could interfere
         ;;   with project switching.
         projectile-project-root)
    (when persp-mode
      (if (and (not (null +workspaces-on-switch-project-behavior))
               (or (eq +workspaces-on-switch-project-behavior t)
                   (+workspace--protected-p (safe-persp-name (get-current-persp)))
                   (+workspace-buffer-list)))
          (let* ((ws-param '+workspace-project)
                 (ws (+workspace-get pname t))
                 (ws (if (and ws
                              (ignore-errors
                                (file-equal-p (persp-parameter ws-param ws)
                                              proot)))
                         ws
                       ;; Uniquify the project's name, so we don't clobber a
                       ;; pre-existing workspace with the same name.
                       (let* ((parts (nreverse (split-string proot "/" t)))
                              (pre  (cdr parts))
                              (post (list (car parts))))
                         (while (and pre
                                     (setq ws (+workspace-get (setq pname (string-join post "/")) t))
                                     (not (ignore-errors
                                            (file-equal-p (persp-parameter ws-param ws)
                                                          proot))))
                           (push (pop pre) post))
                         (unless pre ws))))
                 (ws (or ws
                         (+workspace-get pname t)
                         (+workspace-new pname))))
            (set-persp-parameter ws-param proot ws)
            (+workspace-switch pname)
            (with-current-buffer (luna-fallback-buffer)
              (setq-local default-directory proot)
              (hack-dir-local-variables-non-file-buffer))
            (unless current-prefix-arg
              (funcall +workspaces-switch-project-function proot))
            (+workspace-message
             (format "Switched to '%s' in new workspace" pname)
             'success))
        (with-current-buffer (luna-fallback-buffer)
          (setq-local default-directory proot)
          (hack-dir-local-variables-non-file-buffer)
          (message "Switched to '%s'" pname))
        (with-demoted-errors "Workspace error: %s"
          (+workspace-rename (+workspace-current-name) pname))
        (unless current-prefix-arg
          (funcall +workspaces-switch-project-function proot))))))

;; Tab-bar integration helpers
(defun +workspaces-save-tab-bar-data-h (&rest _)
  "Save the current workspace's tab bar data."
  (when (get-current-persp)
    (set-persp-parameter
     'tab-bar-tabs (tab-bar-tabs))
    (set-persp-parameter 'tab-bar-closed-tabs tab-bar-closed-tabs)))

(defun +workspaces-save-tab-bar-data-to-file-h (&rest _)
  "Save the current workspace's tab bar data to file."
  (when (get-current-persp)
    ;; HACK: Remove fields (for window-configuration) that cannot be serialized.
    (set-persp-parameter 'tab-bar-tabs
                         (frameset-filter-tabs (tab-bar-tabs) nil nil t))))

(defun +workspaces-load-tab-bar-data-h (&rest _)
  "Restores the tab bar data of the workspace we have just switched to."
  (tab-bar-tabs-set (persp-parameter 'tab-bar-tabs))
  (setq tab-bar-closed-tabs (persp-parameter 'tab-bar-closed-tabs))
  (tab-bar--update-tab-bar-lines t))

(defun +workspaces-load-tab-bar-data-from-file-h (&rest _)
  "Restores the tab bar data from file."
  (when-let* ((persp-tab-data (persp-parameter 'tab-bar-tabs)))
    (tab-bar-tabs-set persp-tab-data)
    (tab-bar--update-tab-bar-lines t)))

(defun +workspaces-set-up-tab-bar-integration-h ()
  (add-hook 'persp-before-deactivate-functions #'+workspaces-save-tab-bar-data-h)
  (add-hook 'persp-activated-functions #'+workspaces-load-tab-bar-data-h)
  (add-hook 'persp-before-save-state-to-file-functions #'+workspaces-save-tab-bar-data-to-file-h)
  (+workspaces-load-tab-bar-data-from-file-h))

;;; Advice
(defun +workspaces-autosave-real-buffers-a (fn &rest args)
  "Don't autosave if no real buffers are open."
  (when (cl-remove-if-not #'luna-real-buffer-p (buffer-list))
    (apply fn args))
  t)

;; APROX: doom's `doom/kill-all-buffers' (doom-core); local equivalent.
(defun +workspaces-kill-buffers (buffers)
  "Kill BUFFERS (a list), returning the count killed."
  (let ((count 0))
    (dolist (buf buffers count)
      (when (buffer-live-p buf)
        (cl-incf count)
        (with-current-buffer buf (kill-buffer))))))

;; APROX: doom's `doom-kill-childframes-h' (doom-core); kill child frames after
;;   loading a session so broken ones don't persist.
(defun +workspaces-kill-childframes-h (&rest _)
  (dolist (frame (frame-list))
    (when (frame-parameter frame 'child-frame-parameters)
      (delete-frame frame))))

(leaf persp-mode
  :ensure t
  :demand t
  :commands persp-switch-to-buffer
  :config
  (setq persp-autokill-buffer-on-remove 'kill-weak
        persp-reset-windows-on-nil-window-conf nil
        persp-nil-hidden t
        persp-auto-save-fname "autosave"
        persp-save-dir (expand-file-name "workspaces" lunaris-cache-dir)
        persp-set-last-persp-for-new-frames t
        persp-switch-to-added-buffer nil
        persp-kill-foreign-buffer-behaviour 'kill
        persp-remove-buffers-from-nil-persp-behaviour nil
        persp-auto-resume-time -1 ; Don't auto-load on startup
        persp-auto-save-opt 0) ; no workspace autosave

  ;; The default perspective persp-mode creates is special and doesn't represent
  ;; a real persp object, so buffers can't really be assigned to it, among other
  ;; quirks, so we replace it with a "main" perspective.
  (add-hook 'persp-mode-hook #'+workspaces-ensure-no-nil-workspaces-h)
  (add-hook 'persp-after-load-state-functions #'+workspaces-ensure-no-nil-workspaces-h)
  (add-hook 'persp-mode-hook #'+workspaces-init-first-workspace-h)
  (add-hook 'persp-mode-hook #'+workspaces-init-persp-mode-h)

  ;; Per-workspace `winner-mode' history
  (add-to-list 'window-persistent-parameters '(winner-ring . t))
  (add-hook 'persp-before-deactivate-functions #'+workspaces-save-winner-data-h)
  (add-hook 'persp-activated-functions #'+workspaces-load-winner-data-h)

  ;;; Registering buffers to perspectives
  (add-hook 'window-buffer-change-functions #'+workspaces-add-current-buffer-h)
  (add-hook 'persp-add-buffer-on-after-change-major-mode-filter-functions
            #'+workspaces-unreal-buffer-p)

  ;; Per-frame workspaces
  (setq persp-init-frame-behaviour t
        persp-init-new-frame-behaviour-override nil
        persp-interactive-init-frame-behaviour-override #'+workspaces-associate-frame-fn
        persp-emacsclient-init-frame-behaviour-override #'+workspaces-associate-frame-fn)
  (add-hook 'delete-frame-functions #'+workspaces-delete-associated-workspace-h)
  (add-hook 'server-done-hook #'+workspaces-delete-associated-workspace-h)

  ;; APROX: doom wired `projectile-switch-project-action' here; projectile isn't
  ;; ported. `+workspaces-switch-to-project-h' remains available for manual use.

  ;; Don't bother auto-saving the session if no real buffers are open.
  (advice-add #'persp-asave-on-exit :around #'+workspaces-autosave-real-buffers-a)

  ;; Fix visual selection surviving workspace changes
  (add-hook 'persp-before-deactivate-functions (lambda (&rest _) (deactivate-mark)))

  ;; Stop session persisting broken childframes
  (add-hook 'persp-after-load-state-functions #'+workspaces-kill-childframes-h)

  ;; Don't try to persist dead/remote buffers. They cause errors.
  (add-hook 'persp-filter-save-buffers-functions #'+workspaces-dead-buffer-p)
  (add-hook 'persp-filter-save-buffers-functions #'+workspaces-remote-buffer-p)

  ;; Otherwise, buffers opened via bookmarks aren't treated as "real" and are
  ;; excluded from the buffer list.
  (add-hook 'bookmark-after-jump-hook #'+workspaces-add-current-buffer-h)

  ;; `eshell'
  (persp-def-buffer-save/load
   :mode 'eshell-mode :tag-symbol 'def-eshell-buffer
   :save-vars '(major-mode default-directory))
  ;; `compile'
  (persp-def-buffer-save/load
   :mode 'compilation-mode :tag-symbol 'def-compilation-buffer
   :save-vars '(major-mode default-directory compilation-directory
                compilation-environment compilation-arguments))
  ;; `magit'
  (persp-def-buffer-save/load
   :mode 'magit-status-mode :tag-symbol 'def-magit-status-buffer
   :save-vars '(default-directory)
   :load-function (lambda (savelist &rest _)
                    (magit-status (alist-get 'default-directory (caddr savelist)))))

  ;; `tab-bar'
  (add-hook 'tab-bar-mode-hook #'+workspaces-set-up-tab-bar-integration-h)

  (unless noninteractive
    (persp-mode +1)))

;;; ui-config.el ends here

;;; ui/workspaces.el ends here
