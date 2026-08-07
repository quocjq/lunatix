;;; ui-config.el --- visual chrome, doom :ui set  -*- lexical-binding: t; -*-

;; Port of doom-emacs :ui submodules: deft, doom, dashboard, hl-todo,
;; indent-guides, ligatures, modeline, ophints, popup, smooth-scroll,
;; vc-gutter, window-select, workspaces.
;;
;; ui/unicode has no config.el -- skipped (its autoload only hooks doom-core's
;; `after-setting-font-hook'); the unicode-fonts package is still declared below.
;;
;; APROX markers note where doom-core machinery was replaced with a vanilla or
;; popper equivalent (doom-popup, doom/help, nerd-icons, doom's no-op hooks).

;;; deft
(leaf deft
  :ensure t
  :commands deft
  :bind ("C-c d" . deft)
  :init
  (setq deft-directory "~/Documents/notes"
        deft-default-extension "org"
        ;; de-couples filename and note title:
        deft-use-filename-as-title nil
        deft-use-filter-string-for-filename t
        ;; disable auto-save
        deft-auto-save-interval -1.0
        ;; converts the filter string into a readable file-name using kebab-case:
        deft-file-naming-rules
        '((noslash . "-")
          (nospace . "-")
          (case-fn . downcase)))
  :config
  (add-to-list 'deft-extensions "tex")
  (add-hook 'deft-mode-hook #'doom-mark-buffer-as-real-h)
  (after! evil (evil-set-initial-state 'deft-mode 'insert))
  (map! :map deft-mode-map
        :n "gr"  #'deft-refresh
        :n "C-s" #'deft-filter
        :i "C-n" #'deft-new-file
        :i "C-m" #'deft-new-file-named
        :i "C-d" #'deft-delete-file
        :i "C-r" #'deft-rename-file
        :n "r"   #'deft-rename-file
        :n "a"   #'deft-new-file
        :n "A"   #'deft-new-file-named
        :n "d"   #'deft-delete-file
        :n "D"   #'deft-archive-file
        :n "q"   #'kill-current-buffer)
  ;; APROX: doom's `:localleader' isn't in the compat map!; bind the prefix
  ;; directly with general-def.
  (general-def :keymaps 'deft-mode-map :prefix doom-localleader-key
    "RET" #'deft-new-file-named
    "a"   #'deft-archive-file
    "c"   #'deft-filter-clear
    "d"   #'deft-delete-file
    "f"   #'deft-find-file
    "g"   #'deft-refresh
    "l"   #'deft-filter
    "n"   #'deft-new-file
    "r"   #'deft-rename-file
    "s"   #'deft-toggle-sort-method
    "t"   #'deft-toggle-incremental-search))


;;; :ui doom (themes bits)
;; pos-tip is not a declared dep; the setq is harmless if it's never loaded.
(setq pos-tip-internal-border-width 6
      pos-tip-border-width 1)

(leaf doom-themes
  :ensure t
  ;; doom's solaire-mode (dim non-focussed buffers) is not in this config's
  ;; package set; dropped. Theme loading itself lives in theme-config.el.
  :hook (doom-load-theme . doom-themes-org-config)
  :init
  (setq doom-theme 'doom-one))

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
  \\='last-project  The `doom-project-root' of the last open buffer, or
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
     :when (file-directory-p (doom-user-dir))
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
;; APROX: compat's `doom-fallback-buffer' returns *scratch*; the dashboard
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
    (add-hook 'doom-load-theme-hook #'+dashboard-reload-on-theme-change-h)
    ;; APROX: doom hooked `doom-switch-buffer-hook' (a no-op hook in the compat
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

;; doom ran this on `doom-init-ui-hook' (a no-op hook in the compat layer);
;; run it after startup instead, when frames/windows exist.
(add-hook 'emacs-startup-hook #'+dashboard-init-h 'append)

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

(defun +dashboard-reload-maybe-h (&rest _)
  "Reload the dashboard or its state.

If this isn't a dashboard buffer, move along, but record its `default-directory'
if the buffer is real. If this is the dashboard buffer, reload it completely."
  (cond ((+dashboard-buffer-p (current-buffer))
         (let (+dashboard-inhibit-refresh)
           (ignore-errors (+dashboard-reload))))
        ((and (not (file-remote-p default-directory))
              (doom-real-buffer-p (current-buffer)))
         (setq +dashboard--last-cwd default-directory)
         (+dashboard-update-pwd-h))))

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
  "Record the last `doom-project-root' for the current persp."
  (when (bound-and-true-p persp-mode)
    (set-persp-parameter
     'last-project-root (doom-project-root)
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
        (doom-log "Changed dashboard's PWD to %s" pwd)
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
      (doom-log "Reloading dashboard at %s" (format-time-string "%T"))
      (with-silent-modifications
        (let ((pt (point)))
          (unless (eq major-mode '+dashboard-mode)
            (+dashboard-mode))
          (erase-buffer)
          (run-hooks '+dashboard-functions)
          (goto-char pt)
          (+dashboard-reposition-point-h))
        (+dashboard-resize-h)
        (+dashboard--persp-detect-project-h)
        (+dashboard-update-pwd-h)
        (current-buffer)))))

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
           (or (doom-project-root lastcwd)
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
  (find-file (expand-file-name "init.el" (doom-user-dir))))

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

;;; :ui hl-todo
(leaf hl-todo
  :ensure t
  :demand t
  :config
  (setq hl-todo-highlight-punctuation ":"
        ;; Don't highlight todo keywords in text-mode derivatives unless in
        ;; comments (e.g. data formats like yaml, json, etc).
        hl-todo-text-modes nil
        hl-todo-keyword-faces
        '(;; For reminders to change or add something at a later date.
          ("TODO" warning bold)
          ;; For code (or code paths) that are broken, unimplemented, or slow,
          ;; and may become bigger problems later.
          ("FIXME" error bold)
          ;; For code that needs to be revisited later, either to upstream it,
          ;; improve it, or address non-critical issues.
          ("REVIEW" font-lock-keyword-face bold)
          ;; For code smells where questionable practices are used intentionally
          ;; and is likely to break in a future update.
          ("HACK" font-lock-constant-face bold)
          ;; For sections of code that just gotta go, and will be gone soon.
          ("DEPRECATED" font-lock-doc-face bold)
          ;; Extra keywords commonly found in the wild, whose meaning may vary
          ;; from project to project.
          ("BUG" error bold)
          ("XXX" font-lock-constant-face bold)
          ("NOTE" success bold)))

  (defadvice! +hl-todo-clamp-font-lock-fontify-region-a (fn &rest args)
    ;; Fix an `args-out-of-range' error in some modes.
    :around #'hl-todo-mode
    (cl-letf (((symbol-function #'font-lock-fontify-region)
               (lambda (beg end &optional loudly)
                 (funcall (symbol-function #'font-lock-fontify-region)
                          (max beg 1) end loudly))))
      (apply fn args)))

  ;; APROX: doom hooked `doom-first-buffer' (a no-op hook in the compat layer);
  ;; enable the global mode at startup instead.
  (global-hl-todo-mode +1))

;; Use a more primitive todo-keyword detection method in major modes that
;; don't use/have a valid syntax table entry for comments.
(defun +hl-todo--use-face-detection-h ()
  "Use a different, more primitive method of locating todo keywords."
  (set (make-local-variable 'hl-todo-keywords)
       '(((lambda (limit)
            (let (case-fold-search)
              (and (re-search-forward hl-todo-regexp limit t)
                   (memq 'font-lock-comment-face
                         (ensure-list (get-text-property (point) 'face))))))
          (1 (hl-todo-get-face) t t))))
  (when hl-todo-mode
    (hl-todo-mode -1)
    (hl-todo-mode +1)))

(add-hook 'pug-mode-hook #'+hl-todo--use-face-detection-h)
(add-hook 'haml-mode-hook #'+hl-todo--use-face-detection-h)


;;; :ui indent-guides
(defcustom +indent-guides-inhibit-functions ()
  "A list of predicate functions.

Each function will be run in the context of a buffer where `indent-bars' should
be enabled. If any function returns non-nil, the mode will not be activated."
  :type 'hook
  :group 'indent-guides)

(leaf indent-bars
  :ensure t
  :demand t
  :init
  (defun +indent-guides-startup-h ()
    "Set up indent-bars to activate after startup."
    (add-hook 'after-change-major-mode-hook #'+indent-guides-init-maybe-h 95))

  (defun +indent-guides-init-maybe-h ()
    "Enable `indent-bars-mode' depending on `+indent-guides-inhibit-functions'."
    (unless (or (eq major-mode 'fundamental-mode)
                (doom-temp-buffer-p (current-buffer))
                (run-hook-with-args-until-success '+indent-guides-inhibit-functions))
      (indent-bars-mode +1)))

  :config
  (setq indent-bars-treesit-support (modulep! :tools tree-sitter)
        indent-bars-prefer-character
        (or
         ;; Bitmaps are far slower on MacOS; use characters there.
         (eq system-type 'darwin)
         ;; FIX: A bitmap init bug in emacs-pgtk (before v30) could cause
         ;; crashes (see jdtsmith/indent-bars#3).
         (and (featurep 'pgtk)
              (< emacs-major-version 30)))
        ;; Show indent guides starting from the first column.
        indent-bars-starting-column 0
        ;; Make indent guides subtle; the default is too distractingly colorful.
        indent-bars-width-frac 0.15  ; make bitmaps thinner
        indent-bars-color-by-depth nil
        indent-bars-color '(font-lock-comment-face :face-bg nil :blend 0.425)
        ;; Don't highlight current level indentation; it's distracting and is
        ;; unnecessary overhead for little benefit.
        indent-bars-highlight-current-depth nil
        ;; `least' doesn't suffer the scrolling issue of `t'.
        indent-bars-display-on-blank-lines 'least)

  ;; indent-bars adds this to `enable-theme-functions' (introduced in 29.1),
  ;; which will be redundant with `doom-load-theme-hook'.
  (unless (boundp 'enable-theme-functions)
    (add-hook 'doom-load-theme-hook #'indent-bars-reset-styles))

  (defadvice! +indent-guides--prevent-passing-newline-a (fn col &rest args)
    :around #'move-to-column
    (if-let* ((indent-bars-mode)
              (indent-bars-display-on-blank-lines)
              (nlp (line-end-position))
              (dprop (get-text-property nlp 'display))
              ((seq-contains-p dprop ?\n))
              ((> col (- nlp (point)))))
        (goto-char nlp)
      (apply fn col args)))

  ;; HACK: `indent-bars-mode' interacts with some packages poorly. Fix
  ;; interop with magit-blame, lsp-ui-peek and vimish-fold.
  (when (modulep! :tools magit)
    (after! magit-blame
      (add-to-list 'magit-blame-disable-modes 'indent-bars-mode)))

  (let ((hide
         (lambda (beg end)
           (save-excursion
             (let ((indent-bars--display-function #'ignore)
                   (indent-bars--display-blank-lines-function #'ignore))
               (indent-bars--fontify beg (1+ end) nil)))))
        (restore
         (lambda (beg end)
           (save-excursion
             (indent-bars--fontify beg (1+ end) nil)))))
    (when (modulep! :tools lsp)
      (defadvice! +indent-guides--remove-after-lsp-ui-peek-a (&rest _)
        :after #'lsp-ui-peek--peek-new
        (when (and indent-bars-mode
                   (not indent-bars-prefer-character)
                   (overlayp lsp-ui-peek--overlay))
          (funcall hide
                   (overlay-start lsp-ui-peek--overlay)
                   (overlay-end lsp-ui-peek--overlay))))
      (defadvice! +indent-guides--restore-after-lsp-ui-peek-a (&rest _)
        :before #'lsp-ui-peek--peek-hide
        (when (and indent-bars-mode indent-bars-prefer-character)
          (funcall restore
                   (overlay-start lsp-ui-peek--overlay)
                   (overlay-end lsp-ui-peek--overlay)))))

    (when (modulep! :editor fold)
      (defadvice! +indent-guides--remove-overlays-in-vimish-fold-a (beg end)
        :after #'vimish-fold
        (when (and indent-bars-mode (not indent-bars-prefer-character))
          (cl-destructuring-bind (beg . end) (vimish-fold--correct-region beg end)
            (dolist (ov (vimish-fold--folds-in beg end))
              (funcall hide (overlay-start ov) (overlay-end ov))))))
      (defadvice! +indent-guides--fix-overlays-after-unfold-a (fn overlay)
        :around #'vimish-fold--unfold
        (when (vimish-fold--vimish-overlay-folded-p overlay)
          (let ((beg (overlay-start overlay))
                (end (overlay-end overlay)))
            (prog1 (funcall fn overlay)
              (when (and indent-bars-mode (not indent-bars-prefer-character))
                (funcall restore beg end)))))))))

;; APROX: doom hooked `doom-first-buffer' (a no-op hook in the compat layer);
;; enable after startup instead.
(add-hook 'emacs-startup-hook #'+indent-guides-startup-h)

;; Buffers that may have special fontification or may be invisible to the user.
;; APROX: doom also checked `doom-special-buffer-p' (doom-core, not ported).
(defun +indent-guides-in-special-buffers-p ()
  (and (not (derived-mode-p 'text-mode 'prog-mode 'conf-mode))
       (or buffer-read-only
           (bound-and-true-p cursor-intangible-mode))))
;; Org's virtual indentation messes up indent-guides.
(defun +indent-guides-in-org-indent-mode-p ()
  (bound-and-true-p org-indent-mode))

(add-hook '+indent-guides-inhibit-functions #'+indent-guides-in-special-buffers-p)
(add-hook '+indent-guides-inhibit-functions #'+indent-guides-in-org-indent-mode-p)
(add-hook '+indent-guides-inhibit-functions #'frame-parent)

;;; :ui ligatures
(defvar +ligatures-extra-symbols
  '(;; org
    :name          "»"
    :src_block     "»"
    :src_block_end "«"
    :quote         "“"
    :quote_end     "”"
    ;; Functional
    :lambda        "λ"
    :def           "ƒ"
    :composition   "∘"
    :map           "↦"
    ;; Types
    :null          "∅"
    :true          "𝕋"
    :false         "𝔽"
    :int           "ℤ"
    :float         "ℝ"
    :str           "𝕊"
    :bool          "𝔹"
    :list          "𝕃"
    ;; Flow
    :not           "￢"
    :in            "∈"
    :not-in        "∉"
    :and           "∧"
    :or            "∨"
    :for           "∀"
    :some          "∃"
    :return        "⟼"
    :yield         "⟻"
    ;; Other
    :union         "⋃"
    :intersect     "∩"
    :diff          "∖"
    :tuple         "⨂"
    :pipe          "" ;; FIXME: find a non-private char
    :dot           "•")
  "Maps identifiers to symbols, recognized by `set-ligatures'.")

(defvar +ligatures-alist
  '((prog-mode "|||>" "<|||" "<==>" "<!--" "####" "~~>" "***" "||=" "||>"
               ":::" "::=" "=:=" "===" "==>" "=!=" "=>>" "=<<" "=/=" "!=="
               "!!." ">=>" ">>=" ">>>" ">>-" ">->" "->>" "-->" "---" "-<<"
               "<~~" "<~>" "<*>" "<||" "<|>" "<$>" "<==" "<=>" "<=<" "<->"
               "<--" "<-<" "<<=" "<<-" "<<<" "<+>" "</>" "###" "#_(" "..<"
               "..." "+++" "/==" "///" "_|_" "www" "&&" "^=" "~~" "~@" "~="
               "~>" "~-" "**" "*>" "*/" "||" "|}" "|]" "|=" "|>" "|-" "{|"
               "[|" "]#" "::" ":=" ":>" ":<" "$>" "==" "=>" "!=" "!!" ">:"
               ">=" ">>" ">-" "-~" "-|" "->" "--" "-<" "<~" "<*" "<|" "<:"
               "<$" "<=" "<>" "<-" "<<" "<+" "</" "#{" "#[" "#:" "#=" "#!"
               "##" "#(" "#?" "#_" "%%" ".=" ".-" ".." ".?" "+>" "++" "?:"
               "?=" "?." "??" ";;" "/*" "/=" "/>" "//" "__" "~~" "(*" "*)"
               "\\\\" "://")
    (t))
  "An alist of ligatures to enable in specific modes.

To configure this variable, use `set-ligatures!'.")

(defvar +ligatures-prog-mode-list nil
  "A list of ligatures to enable in all `prog-mode' buffers.")
(make-obsolete-variable '+ligatures-prog-mode-list "Use `+ligatures-alist' instead" "24.09.0")

(defvar +ligatures-all-modes-list nil
  "A list of ligatures to enable in all buffers.")
(make-obsolete-variable '+ligatures-all-modes-list "Use `+ligatures-alist' instead" "24.09.0")

(defvar +ligatures-extra-alist '((t))
  "A map of major modes to symbol lists (for `prettify-symbols-alist').

To configure this variable, use `set-ligatures!'.")

(defvar +ligatures-extras-in-modes t
  "List of major modes where extra ligatures should be enabled.

Extra ligatures are mode-specific substitutions, defined in
`+ligatures-extra-symbols' and assigned with `set-ligatures!'. This variable
controls where these are enabled.

If t, enable it everywhere (except `fundamental-mode').
If the first element is not, enable it in any mode besides what is listed.
If nil, don't enable these extra ligatures anywhere.")

(defun +ligatures--enable-p (modes)
  "Return t if ligatures should be enabled in this buffer depending on MODES."
  (unless (eq major-mode 'fundamental-mode)
    (or (eq modes t)
        (if (eq (car modes) 'not)
            (not (apply #'derived-mode-p (cdr modes)))
          (apply #'derived-mode-p modes)))))

(defun +ligatures-init-extra-symbols-h ()
  "Set up `prettify-symbols-mode' for the current buffer.

Overwrites `prettify-symbols-alist' and activates `prettify-symbols-mode' if
(and only if) there is an associated entry for the current major mode (or a
parent mode) in `+ligatures-extra-alist' AND the current mode (or a parent mode)
isn't disabled in `+ligatures-extras-in-modes'."
  (when after-init-time
    (when-let*
        (((+ligatures--enable-p +ligatures-extras-in-modes))
         (symbols
          (if-let* ((symbols (assq major-mode +ligatures-extra-alist)))
              (cdr symbols)
            (cl-loop for (mode . symbols) in +ligatures-extra-alist
                     if (derived-mode-p mode)
                     return symbols))))
      (setq prettify-symbols-alist
            (append symbols
                    ;; Don't overwrite global defaults
                    (default-value 'prettify-symbols-alist)))
      (when (bound-and-true-p prettify-symbols-mode)
        (prettify-symbols-mode -1))
      (prettify-symbols-mode +1))))

;; When you get to the right edge, it goes back to how it normally prints
(setq prettify-symbols-unprettify-at-point 'right-edge)

(when (modulep! +extra)
  (add-hook 'after-change-major-mode-hook #'+ligatures-init-extra-symbols-h))

;; APROX: doom's cond used emacs-mac/harfbuzz feature detection; this config
;; just uses the ligature package directly (works on harfbuzz builds).
(leaf ligature
  :ensure t
  :demand t
  :config
  (with-no-warnings
    (when +ligatures-prog-mode-list
      (setf (alist-get 'prog-mode +ligatures-alist) +ligatures-prog-mode-list))
    (when +ligatures-all-modes-list
      (setf (alist-get t +ligatures-alist) +ligatures-all-modes-list)))
  (dolist (lig +ligatures-alist)
    (ligature-set-ligatures (car lig) (cdr lig)))
  (global-ligature-mode 1))

(defun set-ligatures! (modes &rest plist)
  "Associate string patterns with icons in certain major-modes.

MODES is a major mode symbol or a list of them.
PLIST is a property list whose keys must match keys in
`+ligatures-extra-symbols', and whose values are strings representing the text
to be replaced with that symbol.

If the car of PLIST is nil, then unset any pretty symbols and ligatures
previously defined for MODES."
  (declare (indent defun))
  (if (null (car-safe plist))
      (dolist (mode (ensure-list modes))
        (setf (alist-get mode +ligatures-extra-alist nil t) nil))
    (let ((results))
      (while plist
        (let ((key (pop plist)))
          (when-let* ((char (plist-get +ligatures-extra-symbols key)))
            (push (cons (pop plist) char) results))))
      (dolist (mode (ensure-list modes))
        (setf (alist-get mode +ligatures-extra-alist)
              (if-let* ((old-results (alist-get mode +ligatures-extra-alist)))
                  (dolist (cell results old-results)
                    (setf (alist-get (car cell) old-results) (cdr cell)))
                results))))))

(defun set-font-ligatures! (modes &rest ligatures)
  "Associate string patterns with ligatures in certain major-modes.

MODES is a major mode symbol or a list of them.
LIGATURES is a list of ligatures that should be handled by the font, like \"==\"
or \"-->\"."
  (declare (indent defun))
  (after! ligature
    (if (or (null ligatures) (equal ligatures '(nil)))
        (dolist (table ligature-composition-table)
          (let ((modes (ensure-list modes))
                (tmodes (car table)))
            (cond ((and (listp tmodes) (cl-intersection modes tmodes))
                   (let ((tmodes (cl-nset-difference tmodes modes)))
                     (setq ligature-composition-table
                           (if tmodes
                               (cons tmodes (cdr table))
                             (delete table ligature-composition-table)))))
                  ((memq tmodes modes)
                   (setq ligature-composition-table (delete table ligature-composition-table))))))
      (ligature-set-ligatures modes ligatures))))


;;; :ui unicode (ui/unicode has no config.el; doom's autoload only hooked
;;; doom-core's `after-setting-font-hook'). Keep vanilla unicode-fonts setup.
(leaf unicode-fonts
  :ensure t
  :demand t
  :config
  (unicode-fonts-setup))

;;; :ui modeline
(leaf doom-modeline
  :ensure t
  :demand t
  :hook (doom-modeline-mode . size-indication-mode) ; filesize in modeline
  :hook (doom-modeline-mode . column-number-mode)   ; cursor column in modeline
  :init
  ;; We display project info in the modeline ourselves
  (setq projectile-dynamic-mode-line nil)
  ;; Set these early so they don't trigger variable watchers
  (setq doom-modeline-bar-width 3
        doom-modeline-github nil
        doom-modeline-mu4e nil
        doom-modeline-persp-name nil
        doom-modeline-minor-modes nil
        doom-modeline-major-mode-icon nil
        doom-modeline-check 'simple  ; default is too busy
        doom-modeline-buffer-file-name-style 'relative-from-project
        ;; Only show file encoding if it's non-UTF-8 and different line
        ;; endings than the current OSes preference
        doom-modeline-buffer-encoding 'nondefault
        doom-modeline-default-eol-type (if (eq system-type 'windows-nt) 1 0))
  :config
  (doom-modeline-mode 1)

  ;; Fix an issue where these two variables aren't defined in TTY Emacs on
  ;; MacOS
  (defvar mouse-wheel-down-event nil)
  (defvar mouse-wheel-up-event nil)

  ;; doom's `+modeline-resize-for-font-h' hooks `after-setting-font-hook' and
  ;; uses `doom-font-increment' -- both doom-core (not ported); dropped.
  (add-hook 'doom-load-theme-hook #'doom-modeline-refresh-bars)

  (add-to-list 'doom-modeline-mode-alist '(+dashboard-mode . dashboard))
  ;; APROX: anzu/evil-anzu (isearch counts) aren't in this config's package
  ;; set; dropped.

  ;; Show minimal modeline in magit-status buffer, no modeline elsewhere.
  (defun +modeline-hide-in-non-status-buffer-h ()
    (if (eq major-mode 'magit-status-mode)
        (doom-modeline-set-modeline 'magit)
      (mode-line-invisible-mode)))
  (add-hook 'magit-mode-hook #'+modeline-hide-in-non-status-buffer-h))


;;; :ui ophints
(leaf evil-goggles
  :ensure t
  :demand t
  :after evil
  :init
  (setq evil-goggles-duration 0.1
        evil-goggles-pulse nil ; too slow
        ;; evil-goggles provides a good indicator of what has been affected.
        ;; delete/change is obvious, so I'd rather disable it for these.
        evil-goggles-enable-delete nil
        evil-goggles-enable-change nil)
  :config
  (evil-goggles-mode 1)
  ;; The lispyville (+editor lispy) commands aren't enabled, so they're
  ;; omitted; the doom-only `+evil:yank-unindented'/`+eval:region' entries are
  ;; kept (harmless if their commands don't exist).
  (dolist (cmd `((evil-magit-yank-whole-line
                  :face evil-goggles-yank-face
                  :switch evil-goggles-enable-yank
                  :advice evil-goggles--generic-async-advice)
                 (+evil:yank-unindented
                  :face evil-goggles-yank-face
                  :switch evil-goggles-enable-yank
                  :advice evil-goggles--generic-async-advice)
                 (+eval:region
                  :face evil-goggles-yank-face
                  :switch evil-goggles-enable-yank
                  :advice evil-goggles--generic-async-advice)))
    (add-to-list 'evil-goggles--commands cmd)))


;;; :ui popup
;;; APROX: doom's popup system is built on doom-core `doom-popup' (not in the
;;; compat layer). Port the portable parts: the buffer rules plus the toggle,
;;; raise, cycle and close commands -- with popper providing the actual window
;;; mechanics (side windows, display control, ESC-close). The doom-popup
;;; internals (+popup-mode, +popup-buffer-mode, stacked side-window display,
;;; :ttl/:quit/:slot/:modeline semantics) are not portable; only the rule
;;; predicate is carried over into popper's reference-buffer list.

(defun set-popup-rule! (predicate &rest _plist)
  "Lunatix: doom-popup compat. Registers PREDICATE (a buffer-name regexp or
function) as a popper reference buffer. Only the predicate is portable; the
rest of the doom rule plist is ignored (popper has no slot/ttl/quit model)."
  (if (boundp 'popper-reference-buffers)
      (progn
        (add-to-list 'popper-reference-buffers predicate)
        (when (and popper-mode (fboundp 'popper--set-reference-vars))
          (popper--set-reference-vars)))
    (with-eval-after-load 'popper
      (add-to-list 'popper-reference-buffers predicate)))
  popper-reference-buffers)

(defun +popup-buffer-p (&optional buffer)
  "Return non-nil if BUFFER (default the current one) is shown as a popup."
  (popper-popup-p (or buffer (current-buffer))))

(defun +popup/toggle ()
  "Toggle open/closed popups (doom's `+popup/toggle' -> `popper-toggle')."
  (interactive)
  (popper-toggle))

(defun +popup/cycle (&optional n)
  "Cycle through open popups (doom's `+popup/other' -> `popper-cycle')."
  (interactive "p")
  (popper-cycle (or n 1)))

(defalias 'other-popup #'+popup/cycle)

(defun +popup/close ()
  "Close and kill the latest popup (doom's `+popup/close' -> `popper-kill-latest-popup')."
  (interactive)
  (popper-kill-latest-popup))

(defun +popup/raise (&optional buffer)
  "Raise a popup into a regular window (popper `popper-toggle-type')."
  (interactive)
  (popper-toggle-type buffer))

(defun +popup/buffer ()
  "Pop the current buffer into a popup window (doom's `+popup/buffer')."
  (interactive)
  (let ((buf (current-buffer)))
    (add-to-list 'popper-reference-buffers
                 (lambda (b) (eq b buf)))
    (when (and popper-mode (fboundp 'popper--set-reference-vars))
      (popper--set-reference-vars))
    (popper-toggle)))

(leaf popper
  :ensure t
  :demand t
  :bind (("C-'" . popper-toggle)
         ("M-`" . popper-cycle))
  :config
  (setq popper-group-by-direction t
        popper-reference-buffers
        (append
         ;; doom :ui popup rules (the `+defaults' set + vc-gutter's diff-hl
         ;; rule), mapped to popper reference buffers. Rules with `:ignore' in
         ;; doom become (regexp . hide) suppression entries in popper.
         '("\\*Messages\\*" "\\*Backtrace\\*" "\\*Warnings\\*"
           "\\*Compilation\\*" "\\*Process List\\*"
           "^\\*\\(?:[Cc]ompile-Log\\|Messages\\)"
           "^\\*Local Variables\\*" "^\\*Customize"
           "^\\*diff-hl" "^\\*\\(?:Wo\\)?Man " "^\\*Calc"
           "^\\*eww\\*" "^\\*xwidget" "^\\*info\\*$" "^ \\*undo-tree\\*"
           help-mode apropos-mode
           ;; doom `:ignore' rules (these buffers manage their own windows)
           ("^\\*Completions" . hide)
           ("^ \\*transient" . hide)
           ("^\\*\\(?:Proced\\|timer-list\\|Abbrevs\\|Output\\|Occur\\|unsent mail.*?\\|message\\)\\*" . hide))
         popper-reference-buffers))
  (popper-mode 1)
  ;; APROX: doom's `*doom:' / `*Pp E' rules target doom-internal buffers that
  ;; don't exist here; dropped. Doom's `+all' rule set is off by default.
  )

;;; :ui smooth-scroll
(leaf ultra-scroll
  :ensure t
  :demand t
  :config
  (ultra-scroll-mode 1)
  (add-hook 'ultra-scroll-hide-functions #'hl-todo-mode)
  (add-hook 'ultra-scroll-hide-functions #'diff-hl-flydiff-mode)
  (add-hook 'ultra-scroll-hide-functions #'jit-lock-mode))
;; good-scroll (+interpolate flag) isn't in this config's package set; the
;; `+interpolate' flag is off -- dropped.


;;; :ui vc-gutter
;;; Default styles (+pretty flag is on)
(when (modulep! +pretty)
  (if (fboundp 'fringe-mode) (fringe-mode '8))
  (setq-default fringes-outside-margins t)

  (defadvice! +vc-gutter-define-thin-bitmaps-a (&rest _)
    :after #'diff-hl-define-bitmaps
    (let* ((scale (if (and (boundp 'text-scale-mode-amount)
                           (numberp text-scale-mode-amount))
                      (expt text-scale-mode-step text-scale-mode-amount)
                    1))
           (spacing (or (and (display-graphic-p) (default-value 'line-spacing)) 0))
           (total-spacing (pcase spacing
                            ((pred numberp) spacing)
                            (`(,above . ,below) (+ above below))))
           (h (+ (ceiling (* (frame-char-height) scale))
                 (if (floatp total-spacing)
                     (truncate (* (frame-char-height) total-spacing))
                   total-spacing)))
           (w (min (frame-parameter nil (intern (format "%s-fringe" diff-hl-side)))
                   diff-hl-bmp-max-width))
           (_ (if (zerop w) (setq w diff-hl-bmp-max-width))))
      (define-fringe-bitmap 'diff-hl-bmp-middle
        (make-vector
         h (string-to-number (let ((half-w (1- (/ w 2))))
                               (concat (make-string half-w ?1)
                                       (make-string (- w half-w) ?0)))
                             2))
        nil nil 'center)))
  (defun +vc-gutter-type-at-pos-fn (type _pos)
    (if (eq type 'delete)
        'diff-hl-bmp-delete
      'diff-hl-bmp-middle))
  (setq diff-hl-fringe-bmp-function #'+vc-gutter-type-at-pos-fn)
  (setq diff-hl-draw-borders nil)

  (after! diff-hl
    (defun +vc-gutter-make-diff-hl-faces-transparent-h ()
      ;; APROX: doom used `doom-rpartial' (doom-core); inline the lambda.
      (mapc (lambda (face) (set-face-background face nil))
            '(diff-hl-insert diff-hl-delete diff-hl-change)))
    (add-hook 'diff-hl-mode-hook #'+vc-gutter-make-diff-hl-faces-transparent-h)
    (add-hook 'doom-load-theme-hook #'+vc-gutter-make-diff-hl-faces-transparent-h))

  ;; FIX: To minimize overlap between flycheck indicators and diff-hl
  ;;   indicators in the left fringe.
  (after! flycheck
    ;; Let diff-hl have left fringe, flycheck can have right fringe
    (setq flycheck-indication-mode 'right-fringe)
    ;; A non-descript, left-pointing arrow
    (define-fringe-bitmap 'flycheck-fringe-bitmap-double-arrow
      [16 48 112 240 112 48 16] nil nil 'center)))

;;; diff-hl
(leaf diff-hl
  :ensure t
  :demand t
  :commands diff-hl-stage-current-hunk diff-hl-revert-hunk diff-hl-next-hunk diff-hl-previous-hunk
  :init
  ;; Conditionally enable `diff-hl-dired-mode' in dired buffers, respecting
  ;; `diff-hl-disable-on-remote'.
  (defun +vc-gutter-enable-maybe-h ()
    (unless (and (bound-and-true-p diff-hl-disable-on-remote)
                 (file-remote-p default-directory))
      (diff-hl-dired-mode +1)))
  (add-hook 'dired-mode-hook #'+vc-gutter-enable-maybe-h)

  ;; APROX: doom skipped flydiff on MacOS via `(featurep :system 'macos)';
  ;; use `system-type'.
  (unless (eq system-type 'darwin)
    ;; Enable on-the-fly vc-gutter updating
    (add-hook 'diff-hl-mode-hook #'diff-hl-flydiff-mode))

  :config
  ;; APROX: doom's popup rule (popper registers "^\\*diff-hl" instead).
  (set-popup-rule! "^\\*diff-hl" :select nil)

  (setq diff-hl-global-modes '(not image-mode pdf-view-mode))
  ;; PERF: A slightly faster algorithm for diffing.
  (setq vc-git-diff-switches '("--histogram"))
  ;; PERF: Slightly more conservative delay before updating the diff.
  (setq diff-hl-flydiff-delay 0.5)  ; default: 0.3
  ;; PERF: don't block Emacs when updating vc gutter
  (setq diff-hl-update-async (or (> emacs-major-version 30) 'thread))
  ;; UX: get realtime feedback in diffs after staging/unstaging hunks.
  (setq diff-hl-show-staged-changes nil)

  ;; HACK: diff-hl exploits the auto-save mechanism to generate its temp file
  ;;   paths in /tmp (in `diff-hl-diff-buffer-with-reference'), which triggers
  ;;   an "autosave file in local temp dir, do you want to continue?" prompt
  ;;   anytime diff-hl wants to save one for TRAMP buffers.
  (defadvice! +vc-gutter--silence-temp-file-prompts-a (fn &rest args)
    :around #'diff-hl-diff-buffer-with-reference
    (let ((tramp-allow-unsafe-temporary-files t))
      (apply fn args)))

  ;; UX: Update diffs when it makes sense too, without being too slow
  (when (modulep! :editor evil)
    (map! :map diff-hl-show-hunk-map
          :n "p" #'diff-hl-show-hunk-previous
          :n "n" #'diff-hl-show-hunk-next
          :n "c" #'diff-hl-show-hunk-copy-original-text
          :n "r" #'diff-hl-show-hunk-revert-hunk
          :n "[" #'diff-hl-show-hunk-previous
          :n "]" #'diff-hl-show-hunk-next
          :n "{" #'diff-hl-show-hunk-previous
          :n "}" #'diff-hl-show-hunk-next
          :n "S" #'diff-hl-show-hunk-stage-hunk))

  ;; UX: Refresh gutter in the selected buffer on ESC, switching windows, or
  ;;   refocusing the frame. APROX: doom's `doom-escape-hook'/`doom-switch-window-hook'
  ;;   are no-op in the compat layer; hook the real `window-buffer-change-functions'.
  (defvar-local +vc-gutter--last-state nil)
  (defun +vc-gutter-update-h (&rest _)
    "Return nil to prevent shadowing other `doom-escape-hook' hooks."
    (when-let* (((or (bound-and-true-p diff-hl-mode)
                     (bound-and-true-p diff-hl-dir-mode)))
                ((not (file-remote-p default-directory)))
                (file (buffer-file-name (buffer-base-buffer)))
                ((not ; debouncing
                  (equal (cons (point) +vc-gutter--last-state)
                         (setq +vc-gutter--last-state
                               (cons (point)
                                     (copy-sequence
                                      (symbol-plist
                                       (intern (expand-file-name file)
                                               vc-file-prop-obarray)))))))))
      (ignore (diff-hl-update))))
  (add-hook 'window-buffer-change-functions #'+vc-gutter-update-h)

  ;; UX: Update diff-hl when magit alters git state.
  (when (modulep! :tools magit)
    (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))

  ;; FIX: The revert popup consumes 50% of the frame, whether or not you're
  ;;   reverting 2 lines or 20. This resizes the popup to match its contents.
  (defadvice! +vc-gutter--shrink-popup-a (fn &rest args)
    :around #'diff-hl-revert-hunk-1
    (let ((refine-mode diff-auto-refine-mode)
          (orig-diff-refine-hunk (symbol-function #'diff-refine-hunk)))
      (cl-letf ((diff-auto-refine-mode t)
                ((symbol-function #'diff-refine-hunk)
                 (lambda (&rest args)
                   (when refine-mode (apply orig-diff-refine-hunk args))
                   (shrink-window-if-larger-than-buffer))))
        (apply fn args))))

  ;; UX: Update diff-hl immediately upon exiting insert mode.
  (when (modulep! :editor evil)
    (defun +vc-gutter-init-flydiff-mode-h ()
      (if diff-hl-flydiff-mode
          (add-hook 'evil-insert-state-exit-hook #'diff-hl-flydiff-update)
        (remove-hook 'evil-insert-state-exit-hook #'diff-hl-flydiff-update)))
    (add-hook 'diff-hl-flydiff-mode-hook #'+vc-gutter-init-flydiff-mode-h))

  ;; FIX: Reverting a hunk causes the cursor to be moved to an unexpected place,
  ;;   often far from the target hunk.
  (defadvice! +vc-gutter--save-excursion-a (fn &rest args)
    ;; Suppresses unexpected cursor movement by `diff-hl-revert-hunk'.
    :around #'diff-hl-revert-hunk
    (let ((pt (point)))
      (prog1 (apply fn args)
        (goto-char pt))))

  (global-diff-hl-mode +1)
  (add-hook 'vc-dir-mode-hook #'turn-on-diff-hl-mode))

;;; +vc-gutter/* commands from ui/vc-gutter/autoload/diff-hl.el
(defalias '+vc-gutter/stage-hunk #'diff-hl-stage-current-hunk)
(defalias '+vc-gutter/next-hunk #'diff-hl-next-hunk)
(defalias '+vc-gutter/previous-hunk #'diff-hl-previous-hunk)

(defun +vc-gutter/revert-hunk (&optional no-prompt)
  "Invoke `diff-hl-revert-hunk'."
  (interactive "P")
  (let ((vc-suppress-confirm (if no-prompt t)))
    (call-interactively #'diff-hl-revert-hunk)))

(defun +vc-gutter/save-and-revert-hunk ()
  "Invoke `diff-hl-revert-hunk' with `vc-suppress-confirm' set."
  (interactive)
  (+vc-gutter/revert-hunk t))

;;; :ui window-select
;; doom uses `switch-window' only with the +switch-window flag (off here), so
;; ace-window handles `other-window'.
(leaf ace-window
  :ensure t
  :defer t
  :init
  (global-set-key [remap other-window] #'ace-window)
  :config
  ;; +numbers is on, so winum provides number-jumping; leave `aw-keys' default.
  (unless (modulep! +numbers)
    (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)))
  (setq aw-scope 'frame
        aw-background t))

(leaf winum
  :ensure t
  :demand t
  :config
  ;; winum modifies `mode-line-format' in a destructive manner. I'd rather leave
  ;; it to modeline plugins (or the user) to add this if they want it.
  (setq winum-auto-setup-mode-line nil)
  (winum-mode +1)
  (map! :map evil-window-map
        "0" #'winum-select-window-0-or-10
        "1" #'winum-select-window-1
        "2" #'winum-select-window-2
        "3" #'winum-select-window-3
        "4" #'winum-select-window-4
        "5" #'winum-select-window-5
        "6" #'winum-select-window-6
        "7" #'winum-select-window-7
        "8" #'winum-select-window-8
        "9" #'winum-select-window-9))


;;; :ui workspaces
(defvar +workspaces-main "main"
  "The name of the primary and initial workspace, which cannot be deleted.")

(defvar +workspaces-switch-project-function #'project-find-file
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
      (switch-to-buffer (doom-fallback-buffer))
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
(defalias '+workspace/restore-last-session #'persp-load-state-from-file)

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
                   (switch-to-buffer (doom-fallback-buffer))))
                (t
                 (+workspace-switch +workspaces-main t)
                 (unless (string= (car workspaces) +workspaces-main)
                   (+workspace-kill name))
                 (+workspaces-kill-buffers
                  (cl-remove-if-not #'doom-real-buffer-p (buffer-list)))))
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
;; APROX: doom added this to `doom-switch-buffer-hook' (no-op here); hook the
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
  (doom-temp-buffer-p buffer))

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
      (unless (doom-real-buffer-p (current-buffer))
        (let (switch-to-buffer-obey-display-actions) ; see #46
          (switch-to-buffer (doom-fallback-buffer))))
      (set-frame-parameter frame 'workspace (+workspace-current-name))
      ;; ensure every buffer has a buffer-predicate
      (persp-set-frame-buffer-predicate frame))
    (run-at-time 0.1 nil #'+workspace/display)))

;; Per-project workspaces, but reuse current workspace if empty
(defun +workspaces--project-name ()
  (let ((root (doom-project-root)))
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
            (with-current-buffer (doom-fallback-buffer)
              (setq-local default-directory proot)
              (hack-dir-local-variables-non-file-buffer))
            (unless current-prefix-arg
              (funcall +workspaces-switch-project-function proot))
            (+workspace-message
             (format "Switched to '%s' in new workspace" pname)
             'success))
        (with-current-buffer (doom-fallback-buffer)
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
  (when (cl-remove-if-not #'doom-real-buffer-p (buffer-list))
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
        persp-save-dir (expand-file-name "workspaces" user-emacs-directory)
        persp-set-last-persp-for-new-frames t
        persp-switch-to-added-buffer nil
        persp-kill-foreign-buffer-behaviour 'kill
        persp-remove-buffers-from-nil-persp-behaviour nil
        persp-auto-resume-time -1 ; Don't auto-load on startup
        persp-auto-save-opt (if noninteractive 0 1)) ; auto-save on kill

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

  ;; Delete the current workspace if closing the last open window
  (map! :map persp-mode-map
        [remap delete-window] #'+workspace/close-window-or-workspace
        [remap evil-window-delete] #'+workspace/close-window-or-workspace)

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
(provide 'ui-config)
