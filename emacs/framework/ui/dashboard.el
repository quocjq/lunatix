;;; ui/dashboard.el --- doom ui/dashboard port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/dashboard.
;;; Code:

;;; :ui dashboard
(defgroup +dashboard nil
  "Manage how the dashboard is coloured and themed."
  :group 'convenience)

(defcustom +dashboard-name "*doom*"
  "The name of the dashboard buffer."
  :type 'string
  :group '+dashboard)

(defcustom +dashboard-functions
  `(+dashboard-widget-banner
    +dashboard-widget-shortmenu
    +dashboard-widget-footer
    +dashboard-widget-loaded)
  "List of widget functions to run to construct the dashboard buffer."
  :type 'hook
  :group '+dashboard)

(define-obsolete-variable-alias '+dashboard-banner-file 'fancy-splash-image "26.07")
(defcustom +dashboard-banner-file "default.png"
  "The path to the image file used on the dashboard. Set
`fancy-splash-image' to use an image instead; nil always uses the ASCII banner."
  :type 'string
  :group '+dashboard)

(defcustom +dashboard-ascii-banner-fn #'+dashboard-draw-ascii-banner-fn
  "The function used to generate the ASCII banner on the dashboard."
  :type 'function
  :group '+dashboard)

(defcustom +dashboard-banner-vertical-padding '(2 . 2)
  "Number of newlines to pad the banner with, above and below, respectively."
  :type '(cons integer integer)
  :group '+dashboard)

(defcustom +dashboard-anchor '(center . center)
  "How to vertically and horizontally align dashboard widgets."
  :type '(cons (choice (const :tag "Top" top)
                       (const :tag "Bottom" bottom)
                       (const :tag "Centered" center))
               (choice (const :tag "Left" left)
                       (const :tag "Right" right)
                       (const :tag "Centered" center)))
  :group '+dashboard)

(defcustom +dashboard-pwd-policy 'last-project
  "The policy to use when setting `default-directory' in the dashboard.

Possible values:
  \\='last-project  The `luna-project-root' of the last open buffer, or
                  `default-directory' if not in a project.
  \\='last          The `default-directory' of the last open buffer.
  a FUNCTION     Run with the `default-directory' of the last open buffer,
                 returning a directory path.
  a STRING       A fixed path.
  nil            `default-directory' never changes."
  :type '(radio
          (const :tag "The project root of the last open buffer (or `default-directory')" last-project)
          (const :tag "The `default-directory' of the last open buffer." last)
          (function :tag "Return what directory to use")
          (directory :tag "A fixed directory path")
          (const :tag "Never change the dashboard's `default-directory'" nil))
  :group '+dashboard)

(defcustom +dashboard-menu-sections
  '(("Recently opened files"
     :icon nil
     :action recentf-open-files)
    ("Reload last session"
     :icon nil
     :when (file-exists-p (expand-file-name persp-auto-save-fname persp-save-dir))
     :action +dashboard/reload-session)
    ("Open org-agenda"
     :icon nil
     :when (fboundp 'org-agenda)
     :action org-agenda)
    ;; doom's "Open project" item used projectile-switch-project; projectile
    ;; isn't ported, so that entry is dropped.
    ("Jump to bookmark"
     :icon nil
     :action bookmark-jump)
    ("Open private configuration"
     :icon nil
     :when (file-directory-p (luna-user-dir))
     :action +dashboard/open-private-config)
    ("Open documentation"
     :icon nil
     :action +dashboard/help))
  "An alist of menu buttons used by `+dashboard-widget-shortmenu'. Each
element is a cons cell (LABEL . PLIST): :action is a command symbol, :when a
FORM, :icon a string (APROX: doom used nerd-icons), :face a face, :key a
keybind hint string."
  :type 'alist
  :group '+dashboard)

(defvar +dashboard-inhibit-refresh nil
  "If non-nil, the doom buffer won't be refreshed.")

(defvar +dashboard-inhibit-functions ()
  "A list of functions which take no arguments. If any return non-nil,
dashboard reloading is inhibited.")

(defvar +dashboard--last-cwd nil)
(defvar +dashboard--reload-timer nil)

;;; Faces
(defface +dashboard-banner '((t (:inherit font-lock-comment-face)))
  "Face used for the DOOM banner on the dashboard"
  :group '+dashboard)

(defface +dashboard-footer '((t (:inherit font-lock-keyword-face)))
  "Face used for the footer on the dashboard"
  :group '+dashboard)

(defface +dashboard-footer-icon '((t (:inherit font-lock-keyword-face)))
  "Face used for the icon of the footer on the dashboard"
  :group '+dashboard)

(defface +dashboard-loaded '((t (:inherit font-lock-comment-face)))
  "Face used for the loaded packages benchmark"
  :group '+dashboard)

(defface +dashboard-menu-desc '((t (:inherit font-lock-constant-face)))
  "Face used for the key description of menu widgets on the dashboard"
  :group '+dashboard)

(defface +dashboard-menu-title '((t (:inherit font-lock-keyword-face)))
  "Face used for the title of menu widgets on the dashboard"
  :group '+dashboard)

;;; Major mode
(define-derived-mode +dashboard-mode special-mode
  (format "Emacs %s" emacs-version)
  "Major mode for the dashboard buffer."
  :syntax-table nil
  :abbrev-table nil
  (buffer-disable-undo)
  (setq-local revert-buffer-function #'+dashboard-revert-buffer-fn)
  (setq truncate-lines t)
  (setq-local whitespace-style nil)
  (setq-local show-trailing-whitespace nil)
  (setq-local hscroll-margin 0)
  (setq-local tab-width 2)
  ;; Don't scroll to follow cursor
  (setq-local scroll-preserve-screen-position nil)
  (setq-local auto-hscroll-mode nil)
  ;; Line numbers are ugly with large margins
  (setq-local display-line-numbers-type nil)
  ;; Ensure the ever-changing margins don't screw with the mode-line's
  ;; right-alignment.
  (setq-local mode-line-right-align-edge 'right-margin)
  ;; Ensure point is always on a button
  (add-hook 'post-command-hook #'+dashboard-reposition-point-h nil 'local)
  ;; hl-line will highlight up to the BOL of the following line, which looks
  ;; ugly, so exclude the newline at EOL.
  (setq-local hl-line-range-function (lambda () (cons (pos-bol) (pos-eol))))
  ;; Local variables are never important in the dashboard, and may cause repeat
  ;; prompts about unsafe/risky variables.
  (setq-local enable-local-variables nil))

(map! :map +dashboard-mode-map
      [left-margin mouse-1]   #'ignore
      [remap forward-button]  #'+dashboard/forward-button
      [remap backward-button] #'+dashboard/backward-button
      [remap push-button]     #'+dashboard/push-button
      "n"       #'forward-button
      "p"       #'backward-button
      "C-n"     #'forward-button
      "C-p"     #'backward-button
      [down]    #'forward-button
      [up]      #'backward-button
      [tab]     #'forward-button
      [backtab] #'backward-button
      ;; Evil remaps
      [remap evil-next-line]     #'forward-button
      [remap evil-previous-line] #'backward-button
      [remap evil-next-visual-line]     #'forward-button
      [remap evil-previous-visual-line] #'backward-button
      [remap evil-paste-pop-next] #'forward-button
      [remap evil-paste-pop]      #'backward-button
      [remap evil-delete]         #'ignore
      [remap evil-delete-line]    #'ignore
      [remap evil-insert]         #'ignore
      [remap evil-append]         #'ignore
      [remap evil-replace]        #'ignore
      [remap evil-enter-replace-state] #'ignore
      [remap evil-change]         #'ignore
      [remap evil-change-line]    #'ignore
      [remap evil-visual-char]    #'ignore
      [remap evil-visual-line]    #'ignore)

;;; Bootstrap
;; APROX: compat's `luna-fallback-buffer' returns *scratch*; the dashboard
;; keeps its own dedicated buffer instead.
(defun +dashboard--fallback-buffer ()
  "Return the dashboard buffer, creating it if necessary."
  (get-buffer-create +dashboard-name))

;; Make the dashboard the initial buffer BEFORE the first frame is created
;; (emacs-startup-hook is too late — scratch would already be shown).
(setq initial-buffer-choice #'+dashboard--fallback-buffer)

(defun +dashboard-init-h ()
  "Initialize the dashboard."
  (unless noninteractive
    (+dashboard-reload t)
    (add-hook 'luna-load-theme-hook #'+dashboard-reload-on-theme-change-h)
    ;; APROX: doom hooked `luna-switch-buffer-hook' (a no-op hook in the compat
    ;; layer); use the real `window-buffer-change-functions' instead.
    (add-hook 'window-size-change-functions #'+dashboard-resize-h)
    (add-hook 'window-buffer-change-functions #'+dashboard-reload-maybe-h)
    (add-hook 'delete-frame-functions #'+dashboard-reload-frame-h)
    ;; `persp-mode' integration: update `default-directory' when switching
    ;; perspectives.
    (add-hook 'persp-created-functions #'+dashboard--persp-record-project-h)
    (add-hook 'persp-activated-functions #'+dashboard--persp-detect-project-h)
    (when (daemonp)
      (add-hook 'persp-activated-functions #'+dashboard-reload-maybe-h))
    (add-hook 'persp-before-switch-functions #'+dashboard--persp-record-project-h)))

;; doom ran this on `luna-init-ui-hook' (a no-op hook in the compat layer);
;; ui-config loads in stage 2 (after startup), so run the dashboard init
;; directly. The call lives at the end of the file (after +dashboard-reload is
;; defined) — calling mid-file would hit the void function in GUI.

;;; Hooks
(defun +dashboard-revert-buffer-fn (&optional _ignore-auto _no-confirm)
  "`revert-buffer-function' for `+dashboard-mode'."
  (+dashboard-reload t))

(defun +dashboard-reposition-point-h ()
  "Trap the point in the buttons."
  (when (eq (current-buffer) (get-buffer +dashboard-name))
    (when (region-active-p)
      (setq deactivate-mark t)
      (when (bound-and-true-p evil-local-mode)
        (evil-change-to-previous-state)))
    (cond ((button-at (point))
           (forward-button 0 nil nil t))
          ((save-restriction
             (narrow-to-region (pos-bol) (pos-eol))
             (forward-button 1 nil nil t)))
          ((backward-button 1 nil nil t))
          ((goto-char (point-min))
           (forward-button 1 nil nil t)))
    ;; Hide the cursor if there are no buttons
    (unless (button-at (point))
      (setq-local cursor-type nil
                  evil-normal-state-cursor (list nil)))))

(defvar +dashboard--last-current-buffer nil
  "Previous current buffer, to reload the dashboard only on entry.")

(defun +dashboard-reload-maybe-h (&rest _)
  "Reload the dashboard or its state.

Reload only when switching INTO the dashboard buffer — not on every
window/buffer change while it stays current (that made the 'loaded' time
widget re-render forever). Otherwise record the real buffer's cwd."
  (cond ((+dashboard-buffer-p (current-buffer))
         (unless (eq +dashboard--last-current-buffer (current-buffer))
           (setq +dashboard--last-current-buffer (current-buffer))
           (let (+dashboard-inhibit-refresh)
             (ignore-errors (+dashboard-reload)))))
        (t
         (setq +dashboard--last-current-buffer (current-buffer))
         (when (and (not (file-remote-p default-directory))
                    (luna-real-buffer-p (current-buffer)))
           (setq +dashboard--last-cwd default-directory)
           (+dashboard-update-pwd-h)))))

(defun +dashboard-reload-frame-h (_frame)
  "Reload the dashboard after a brief pause. This is necessary for new frames,
whose dimensions may not be fully initialized by the time this is run."
  (when (timerp +dashboard--reload-timer)
    (cancel-timer +dashboard--reload-timer)) ; in case this function is run rapidly
  (setq +dashboard--reload-timer
        (run-with-timer 0.1 nil #'+dashboard-reload t)))

(defun +dashboard-resize-h (&rest _)
  "Recenter the dashboard, and reset its margins and fringes."
  (let (buffer-list-update-hook
        window-configuration-change-hook
        window-size-change-functions)
    (when-let* ((windows (get-buffer-window-list (+dashboard--fallback-buffer) nil t)))
      (dolist (w windows)
        (unless (= (window-start w)
                   (or (window-parameter w '+dashboard-last-window-start)
                       1))
          (set-window-start w (or (window-parameter w '+dashboard-last-window-start) 0)))
        (when-let* ((pos (window-parameter w '+dashboard-last-position)))
          (goto-char pos)
          (+dashboard-reposition-point-h))
        (cl-destructuring-bind (left right &rest) (window-fringes w)
          (unless (and (= left 0)
                       (= right 0))
            (set-window-fringes w 0 0))))
      (with-current-buffer (+dashboard--fallback-buffer)
        (save-excursion
          (with-silent-modifications
            (goto-char (point-min))
            (delete-region (line-beginning-position)
                           (save-excursion (skip-chars-forward "\n")
                                           (point)))
            (insert
             (make-string
              (max
               0 (pcase (car-safe +dashboard-anchor)
                   (`top 0)
                   (`center
                    (- (/ (window-height (get-buffer-window)) 2)
                       (round (/ (count-lines (point-min) (point-max))
                                 2))))
                   (`bottom
                    (- (window-height (get-buffer-window))
                       (count-lines (point-min) (point-max))
                       1))
                   (_ 0)))
              ?\n))))))))

(defun +dashboard--persp-detect-project-h (&rest _)
  "Set dashboard's PWD to current persp's `last-project-root', if it exists."
  (when (bound-and-true-p persp-mode)
    (when-let* ((pwd (persp-parameter 'last-project-root)))
      (+dashboard-update-pwd-h pwd))))

(defun +dashboard--persp-record-project-h (&optional persp &rest _)
  "Record the last `luna-project-root' for the current persp."
  (when (bound-and-true-p persp-mode)
    (set-persp-parameter
     'last-project-root (luna-project-root)
     (if (persp-p persp)
         persp
       (get-current-persp)))))

;;; Library
(defun +dashboard-buffer-p (buffer)
  "Returns t if BUFFER is the dashboard buffer."
  (eq buffer (get-buffer +dashboard-name)))

(defun +dashboard-update-pwd-h (&optional pwd)
  "Update `default-directory' in the dashboard buffer."
  (if pwd
      (with-current-buffer (+dashboard--fallback-buffer)
        (luna-log "Changed dashboard's PWD to %s" pwd)
        (setq-local default-directory pwd))
    (let ((new-pwd (+dashboard--pwd)))
      (when (and new-pwd (file-accessible-directory-p new-pwd))
        (+dashboard-update-pwd-h
         (concat (directory-file-name new-pwd)
                 "/"))))))

(defun +dashboard-reload-on-theme-change-h ()
  "Forcibly reload the dashboard when theme changes post-startup."
  (when after-init-time
    (+dashboard-reload 'force)))

(defun +dashboard-reload (&optional force)
  "Update the dashboard buffer (or create it, if it doesn't exist)."
  (when (or (and (not +dashboard-inhibit-refresh)
                 (get-buffer-window (+dashboard--fallback-buffer))
                 (not (window-minibuffer-p (frame-selected-window)))
                 (not (run-hook-with-args-until-success '+dashboard-inhibit-functions)))
            force)
    (with-current-buffer (+dashboard--fallback-buffer)
      (luna-log "Reloading dashboard at %s" (format-time-string "%T"))
      (with-silent-modifications
        (let ((pt (point)))
          (unless (eq major-mode '+dashboard-mode)
            (+dashboard-mode))
          (erase-buffer)
          ;; each widget + post-hook guarded: frame-dependent bits (resize,
          ;; persp, pwd) error on the daemon (no window) and must not blank the
          ;; already-rendered content.
          (condition-case err
              (run-hooks '+dashboard-functions)
            (error (luna-log "dashboard widget error: %s" (error-message-string err))))
          (goto-char pt)
          (condition-case err (+dashboard-reposition-point-h)
            (error (luna-log "dashboard reposition error: %s" (error-message-string err))))
          (current-buffer)))
      (condition-case err (+dashboard-resize-h)
        (error (luna-log "dashboard resize error: %s" (error-message-string err))))
      (condition-case err (+dashboard--persp-detect-project-h)
        (error (luna-log "dashboard persp error: %s" (error-message-string err))))
      (condition-case err (+dashboard-update-pwd-h)
        (error (luna-log "dashboard pwd error: %s" (error-message-string err))))
      (current-buffer))))

;; helpers
(defun +dashboard-strlen (s)
  "Return the unicode-aware string width of S."
  (let ((width (frame-char-width))
        (len (string-pixel-width s)))
    (+ (/ len width)
       (if (zerop (% len width)) 0 1))))

(defun +dashboard-maxlen (str)
  "Return the length of the longest line in multiline STR."
  (with-temp-buffer
    (insert str)
    (goto-char (point-min))
    (let ((width 0))
      (while (< (point) (point-max))
        (let* ((line (buffer-substring (pos-bol) (pos-eol)))
               (len (+dashboard-strlen line)))
          (setq width (max width len)))
        (forward-line 1))
      width)))

(defun +dashboard-insert (&rest lines)
  "Insert LINES into the dashboard buffer.

Applies line-prefix and indent-prefix text properties to respect
`+dashboard-anchor'."
  (let ((lines (delq nil lines)))
    (if-let* ((halign (cdr-safe +dashboard-anchor)))
        (let* ((width (+dashboard-maxlen (string-join lines "\n")))
               (prefix `(space :align-to
                         (- ,halign ,(if (eq halign 'right)
                                         (+ 2 width)
                                       (/ width 2))))))
          (add-text-properties
           (point) (progn (mapc (lambda (l) (insert l "\n")) lines)
                          (point))
           `(line-prefix ,prefix indent-prefix ,prefix)))
      (insert (string-join lines "\n")))))

(defun +dashboard--pwd ()
  (let ((lastcwd +dashboard--last-cwd)
        (policy +dashboard-pwd-policy))
    (cond ((null policy)
           default-directory)
          ((stringp policy)
           (expand-file-name policy lastcwd))
          ((functionp policy)
           (funcall policy lastcwd))
          ((null lastcwd)
           default-directory)
          ((eq policy 'last-project)
           (or (luna-project-root lastcwd)
               lastcwd))
          ((eq policy 'last)
           lastcwd)
          ((warn "`+dashboard-pwd-policy' has an invalid value of '%s'"
                 policy)))))

;;; Widgets
(defun +dashboard-draw-ascii-banner-fn ()
  "Return Doom's default ASCII logo banner."
  (propertize
   (string-join
    '("=================     ===============     ===============   ========  ========"
      "\\\\ . . . . . . .\\\\   //. . . . . . .\\\\   //. . . . . . .\\\\  \\\\. . .\\\\// . . //"
      "||. . ._____. . .|| ||. . ._____. . .|| ||. . ._____. . .|| || . . .\\/ . . .||"
      "|| . .||   ||. . || || . .||   ||. . || || . .||   ||. . || ||. . . . . . . ||"
      "||. . ||   || . .|| ||. . ||   || . .|| ||. . ||   || . .|| || . | . . . . .||"
      "|| . .||   ||. _-|| ||-_ .||   ||. . || || . .||   ||. _-|| ||-_.|\\ . . . . ||"
      "||. . ||   ||-'  || ||  `-||   || . .|| ||. . ||   ||-'  || ||  `|\\_ . .|. .||"
      "|| . _||   ||    || ||    ||   ||_ . || || . _||   ||    || ||   |\\ `-_/| . ||"
      "||_-' ||  .|/    || ||    \\|.  || `-_|| ||_-' ||  .|/    || ||   | \\  / |-_.||"
      "||    ||_-'      || ||      `-_||    || ||    ||_-'      || ||   | \\  / |  `||"
      "||    `'         || ||         `'    || ||    `'         || ||   | \\  / |   ||"
      "||            .===' `===.         .==='.`===.         .===' /==. |  \\/  |   ||"
      "||         .=='   \\_|-_ `===. .==='   _|_   `===. .===' _-|/   `==  \\/  |   ||"
      "||      .=='    _-'    `-_  `='    _-'   `-_    `='  _-'   `-_  /|  \\/  |   ||"
      "||   .=='    _-'          '-__\\._-'         '-_./__-'         `' |. /|  |   ||"
      "||.=='    _-'                                                     `' |  /==.||"
      "=='    _-'                         E M A C S                          \\/   `=="
      "\\   _-'                                                                `-_   /"
      " `''                                                                      ``'")
    "\n")
   'face '+dashboard-banner))

(defun +dashboard-widget-banner ()
  "Draw text and image banner widget in the dashboard buffer."
  (when-let* ((banner (and (functionp +dashboard-ascii-banner-fn)
                           (funcall +dashboard-ascii-banner-fn))))
    (let* ((halign (cdr +dashboard-anchor))
           (width (+dashboard-maxlen banner))
           (text-prefix
            `(space
              :align-to (- ,halign
                           ,(if (eq halign 'right)
                                (+ 2 width)
                              (/ width 2)))))
           (top-pad (or (car-safe +dashboard-banner-vertical-padding) 0))
           (bot-pad (or (cdr-safe +dashboard-banner-vertical-padding) 0))
           (beg (point)))
      (when (> top-pad 0)
        (insert (propertize "\n" 'display `(space :height ,top-pad))))

      (insert banner)
      (if-let* (((stringp fancy-splash-image))
                ((file-readable-p fancy-splash-image))
                (image (create-image (fancy-splash-image-file)))
                (image-prefix
                 `(space :align-to (- ,halign
                                      ,@(if (eq halign 'right)
                                            `(,image 1) `((0.5 . ,image))))))
                (prefix
                 (propertize
                  " " 'display `((when (display-graphic-p) . ,image-prefix)
                                 (when (not (display-graphic-p)) . ,text-prefix)))))
          (progn
            (add-text-properties
             beg (point) `(display ,image line-prefix ,prefix wrap-prefix ,prefix))
            (insert "\n"))
        (add-text-properties
         beg (point) `(line-prefix ,text-prefix indent-prefix ,text-prefix)))

      ;; If the ASCII banner doesn't end in a newline, the last line could be
      ;; inflated by the following display property.
      (unless (and (bolp) (eolp)) (insert "\n"))

      (when (> bot-pad 0)
        (insert (propertize "\n" 'display `(space :height ,bot-pad)))))))

(defun +dashboard-widget-loaded ()
  "Draw the session's startup time."
  ;; APROX: doom used `doom-init-time' + `doom-display-benchmark-h'; compute
  ;; from `before-init-time' instead.
  (when after-init-time
    (+dashboard-insert
     (propertize
      (format "Loaded in %.2fs" (float-time (time-since before-init-time)))
      'face '+dashboard-loaded))))

(defun +dashboard-widget-shortmenu ()
  "Draw dashboard menu items and keybindings.

See `+dashboard-menu-sections' to change the contents of the menu."
  (insert "\n")
  (dolist (section +dashboard-menu-sections)
    (cl-destructuring-bind (label &key icon action when face key) section
      (when (and (fboundp action)
                 (or (null when)
                     (eval when t)))
        (+dashboard-insert
         (let ((icon (if (stringp icon) icon (eval icon t))))
           (format (format " %s%%s%%10s " (if icon "%s\t" "%s"))
                   (or icon "")
                   (with-temp-buffer
                     (insert-text-button
                      label
                      'action (cmd!! action)
                      'face (or face '+dashboard-menu-title)
                      'follow-link t
                      'help-echo
                      (format "%s (%s)" label
                              (propertize (symbol-name action) 'face '+dashboard-menu-desc)))
                     (format "%-38s" (buffer-string)))
                   ;; Lookup command keys dynamically
                   (propertize
                    (or key
                        (when-let*
                            ((keymaps
                              (delq
                               nil (list (when (bound-and-true-p evil-local-mode)
                                           (evil-get-auxiliary-keymap +dashboard-mode-map 'normal))
                                         +dashboard-mode-map)))
                             (key
                              (or (when keymaps
                                    (where-is-internal action keymaps t))
                                  (where-is-internal action nil t))))
                          (with-temp-buffer
                            (save-excursion (insert (key-description key)))
                            (while (re-search-forward "<\\([^>]+\\)>" nil t)
                              (replace-match
                               (let ((str (match-string 1)))
                                 (upcase (substring str 0 (min (length str) 3))))))
                            (buffer-string)))
                        "")
                    'face '+dashboard-menu-desc)))
         (propertize "\n" 'display '(space . (:relative-height 0.01))))))))

(defun +dashboard-widget-footer ()
  "Draw the footer."
  ;; APROX: doom drew a nerd-icons GitHub button; keep it plain text.
  (+dashboard-insert
   (propertize "lunatix" 'face '+dashboard-footer)))

(defun +dashboard-widget-spacer ()
  (+dashboard-insert
   (propertize "\n" 'display `(space . (:relative-height 0.5)))))

;;; Dashboard commands
(defun +dashboard/reload-session ()
  "Reload the last autosaved persp-mode session."
  (interactive)
  (when (bound-and-true-p persp-mode)
    (persp-load-state-from-file)))

(defun +dashboard/open-private-config ()
  "Open this config's init.el."
  (interactive)
  (find-file (expand-file-name "init.el" (luna-user-dir))))

(defun +dashboard/help ()
  "Open the help menu."
  (interactive)
  (help-for-help))

;;; Dashboard commands from ui/dashboard/autoload.el
(defun +dashboard--help-echo ()
  (when-let* ((btn (button-at (point)))
              (msg (button-get btn 'help-echo)))
    (message "%s" msg)))

(defun +dashboard/open (frame)
  "Switch to the dashboard in the current window, of the current FRAME."
  (interactive (list (selected-frame)))
  (with-selected-frame frame
    (switch-to-buffer (+dashboard--fallback-buffer))
    (+dashboard-reload t)))

(defun +dashboard/push-button ()
  "Push a button, but record window state before doing so."
  (interactive)
  (set-window-parameter nil '+dashboard-last-window-start (window-start))
  (set-window-parameter nil '+dashboard-last-position (point))
  (call-interactively #'push-button))

(defun +dashboard/forward-button (n)
  "Like `forward-button', but don't wrap."
  (interactive "p")
  (forward-button n nil)
  (+dashboard--help-echo))

(defun +dashboard/backward-button (n)
  "Like `backward-button', but don't wrap."
  (interactive "p")
  (backward-button n nil)
  (+dashboard--help-echo))

;;; ui/dashboard.el ends here
