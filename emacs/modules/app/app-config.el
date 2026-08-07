;;; app-config.el --- calendar, irc, rss, doom :app set  -*- lexical-binding: t; -*-

;;; app/calendar
(defvar +calendar-open-function #'+calendar/open-calendar
  "Function used to open the calendar.")

(defvar +calendar--wconf nil)

(defun +calendar--init ()
  (require 'calfw)
  (if-let* ((win (get-buffer-window calfw-calendar-buffer-name)))
      (select-window win)
    (call-interactively +calendar-open-function)))

(defun =calendar ()
  "Activate (or switch to) the calfw calendar."
  (interactive)
  (+calendar--init))

(defun +calendar/quit ()
  "Close the calfw calendar buffers."
  (interactive)
  (when (window-configuration-p +calendar--wconf)
    (set-window-configuration +calendar--wconf))
  (setq +calendar--wconf nil)
  (dolist (buf (buffer-list))
    (when (string-match-p "^\\*cfw[:-]" (buffer-name buf))
      (kill-buffer buf))))

(defun +calendar/open-calendar (&rest args)
  "Open the calendar in an org-agenda view."
  (interactive)
  (apply #'calfw-org-open-calendar nil "org-agenda" (face-foreground 'default)
         args)
  (calfw-navi-goto-today-command))

(defun +calendar-calfw-render-button-a (title command &optional state)
  "render-button
 TITLE
 COMMAND
 STATE"
  (let ((text (concat " " title " "))
        (keymap (make-sparse-keymap)))
    (calfw-rt text (if state 'calfw-face-toolbar-button-on
                     'calfw-face-toolbar-button-off))
    (define-key keymap [mouse-1] command)
    (calfw-tp text 'keymap keymap)
    (calfw-tp text 'mouse-face 'highlight)
    text))

(leaf calfw
  :ensure t
  :commands calfw-open-calendar-buffer
  :config
  ;; better frame for calendar
  (setq calfw-face-item-separator-color nil
        calfw-render-line-breaker 'calfw-render-line-breaker-none
        calfw-fchar-junction ?+
        calfw-fchar-vertical-line ?|
        calfw-fchar-horizontal-line ?-
        calfw-fchar-left-junction ?+
        calfw-fchar-right-junction ?+
        calfw-fchar-top-junction ?+
        calfw-fchar-top-left-corner ?+
        calfw-fchar-top-right-corner ?+)
  (define-key calfw-calendar-mode-map "q" #'+calendar/quit)
  (when (modulep! :editor evil +everywhere)
    (evil-set-initial-state 'calfw-calendar-mode 'motion)
    (evil-set-initial-state 'calfw-details-mode 'motion)
    (add-hook 'calfw-calendar-mode-hook #'evil-normalize-keymaps)
    (add-hook 'calfw-details-mode-hook #'evil-normalize-keymaps))
  (map! :map calfw-calendar-mode-map
        :m "q"   #'+calendar/quit
        :m "SPC" #'calfw-show-details-command
        :m "RET" #'calfw-show-details-command
        :m "TAB"     #'calfw-navi-prev-item-command
        :m [tab]     #'calfw-navi-prev-item-command
        :m [backtab] #'calfw-navi-next-item-command
        :m "$"   #'calfw-navi-goto-week-end-command
        :m "."   #'calfw-navi-goto-today-command
        :m "<"   #'calfw-navi-previous-month-command
        :m ">"   #'calfw-navi-next-month-command
        :m "C-h" #'calfw-navi-previous-month-command
        :m "C-l" #'calfw-navi-next-month-command
        :m "D"   #'calfw-change-view-day
        :m "M"   #'calfw-change-view-month
        :m "T"   #'calfw-change-view-two-weeks
        :m "W"   #'calfw-change-view-week
        :m "^"   #'calfw-navi-goto-week-begin-command
        :m "gr"  #'calfw-refresh-calendar-buffer
        :m "h"   #'calfw-navi-previous-day-command
        :m "H"   #'calfw-navi-goto-first-date-command
        :m "j"   #'calfw-navi-next-week-command
        :m "k"   #'calfw-navi-previous-week-command
        :m "l"   #'calfw-navi-next-day-command
        :m "L"   #'calfw-navi-goto-last-date-command
        :m "t"   #'calfw-navi-goto-today-command)
  (map! :map calfw-details-mode-map
        :m "SPC" #'calfw-details-kill-buffer-command
        :m "RET" #'calfw-details-kill-buffer-command
        :m "TAB"     #'calfw-details-navi-prev-item-command
        :m [tab]     #'calfw-details-navi-prev-item-command
        :m [backtab] #'calfw-details-navi-next-item-command
        :m "q"   #'calfw-details-kill-buffer-command
        :m "C-h" #'calfw-details-navi-prev-command
        :m "C-l" #'calfw-details-navi-next-command
        :m "C-k" #'calfw-details-navi-prev-item-command
        :m "C-j" #'calfw-details-navi-next-item-command)
  (add-hook 'calfw-calendar-mode-hook #'doom-mark-buffer-as-real-h)
  ;; mode-line-invisible-mode (doom :ui mode-line) has no equivalent here.
  (add-hook 'calfw-calendar-mode-hook #'doom-disable-line-numbers-h)
  (advice-add #'calfw-render-button :override #'+calendar-calfw-render-button-a))

(leaf calfw-org
  :ensure t
  :commands (calfw-org-open-calendar
             calfw-org-create-source
             calfw-org-create-file-source
             calfw-open-org-calendar-withkevin))

(leaf calfw-cal
  :ensure t
  :commands (calfw-cal-create-source))

(leaf calfw-ical
  :ensure t
  :commands (calfw-ical-create-source))

(leaf org-gcal
  :ensure t
  :defer t
  :init
  (defvar org-gcal-dir (doom-profile-cache-dir t "org-gcal/"))
  (defvar org-gcal-token-file (concat org-gcal-dir "token.gpg")))


;;; app/irc
(defcustom +irc-left-padding 13
  "By how much spaces the left hand side of the line should be padded.
Below a value of 12 this may result in uneven alignment between the various
types of messages."
  :type 'integer)

(defcustom +irc-truncate-nick-char ?~
  "Character displayed when nick > `+irc-left-padding' in length."
  :type 'character)

(defcustom +irc-scroll-to-bottom-on-commands
  '(self-insert-command yank hilit-yank
    evil-paste-after evil-paste-before evil-open-above evil-open-below)
  "Commands which will trigger scrolling to the bottom of the IRC buffer."
  :type '(repeat function))

(defcustom +irc-disconnect-hook nil
  "Runs each hook when circe notices the connection has been disconnected.
Useful for scenarios where an instant reconnect will not be successful."
  :type 'hook)

(defcustom +irc-bot-list '("fsbot" "rudybot")
  "Nicks listed have `circe-fool-face' applied and will not be tracked."
  :type '(repeat string))

(defcustom +irc-defer-notifications nil
  "How long to defer enabling notifications, in seconds (e.g. 5min = 300).

Useful for ZNC users who want to avoid the deluge of notifications during buffer
playback."
  :type 'integer)

(defvar +irc--defer-timer nil)
(defvar +irc--workspace-name "*IRC*")

(defsubst +irc--pad (left right)
  (format (format "%%%ds | %%s" +irc-left-padding)
          (concat "*** " left) right))

(defun +irc--circe-all-buffers ()
  (cl-loop for server in (circe-server-buffers)
           collect server
           nconc
           (with-current-buffer server
             (circe-server-chat-buffers))))

(defvar +irc--consult-circe-source
  `(:name     "circe"
    :hidden   t
    :narrow   ?c
    :category buffer
    :state    ,#'consult--buffer-state
    :items    ,(lambda () (mapcar #'buffer-name (+irc--circe-all-buffers)))))

(defun +irc/vertico-jump-to-channel ()
  "Jump to an open channel or server buffer with vertico."
  (interactive)
  (require 'consult)
  (consult--multi (list (plist-put (copy-sequence +irc--consult-circe-source)
                                   :hidden nil))
                  :narrow nil
                  :require-match t
                  :prompt "Jump to:"
                  :sort nil))

(defun +irc/jump-to-channel (&optional this-server)
  "Jump to an open channel or server buffer. If THIS-SERVER (universal
argument) is non-nil only show channels in current server."
  (interactive "P")
  (call-interactively
   (cond ((modulep! :completion vertico)   #'+irc/vertico-jump-to-channel)
         ((user-error "No jump-to-channel backend is enabled. Enable vertico!")))))

(defun +irc/send-message (who what)
  "Send WHO a message containing WHAT."
  (interactive "sWho: \nsWhat: ")
  (circe-command-MSG who what))

(defun +irc/quit ()
  "Kill current circe session and workgroup."
  (interactive)
  (unless (y-or-n-p "Really kill IRC session?")
    (user-error "Aborted"))
  (let (circe-channel-killed-confirmation
        circe-server-killed-confirmation)
    (when +irc--defer-timer
      (cancel-timer +irc--defer-timer))
    (when (fboundp #'disable-circe-notifications)
      (disable-circe-notifications))
    (dolist (buf (buffer-list))
      (when (with-current-buffer buf (derived-mode-p 'circe-mode))
        (kill-buffer buf)))))

(defun +irc/tracking-next-buffer ()
  "Disables switching to an unread buffer unless in the irc workspace."
  (interactive)
  (when (derived-mode-p 'circe-mode)
    (tracking-next-buffer)))

(defun +irc--add-circe-buffer-to-persp-h ()
  (when (and (bound-and-true-p persp-mode)
             (persp-get-by-name +irc--workspace-name))
    (let ((persp (get-current-persp))
          (buf (current-buffer)))
      ;; Add a new circe buffer to irc workspace when we're in another workspace
      (unless (eq (safe-persp-name persp) +irc--workspace-name)
        (persp-add-buffer buf (persp-get-by-name +irc--workspace-name))
        (persp-remove-buffer buf persp)))))

(defun +irc-circe-message-option-bot-h (nick &rest ignored)
  "Fontify known bots and mark them to not be tracked."
  (when (member nick +irc-bot-list)
    '((text-properties . (face circe-fool-face lui-do-not-track t)))))

(defun +irc-init-circe-notifications-h ()
  (require 'circe-notifications)
  (if (numberp +irc-defer-notifications)
      (setq +irc--defer-timer
            (run-at-time +irc-defer-notifications nil
                         #'enable-circe-notifications))
    (enable-circe-notifications)))

(defun +irc-truncate-nicks-h ()
  "Truncate long nicknames in chat output non-destructively."
  (when-let* ((beg (text-property-any (point-min) (point-max) 'lui-format-argument 'nick)))
    (goto-char beg)
    (let ((end (next-single-property-change beg 'lui-format-argument))
          (nick (plist-get (plist-get (text-properties-at beg) 'lui-keywords)
                           :nick)))
      (when (> (length nick) +irc-left-padding)
        (compose-region (+ beg +irc-left-padding -1) end
                        +irc-truncate-nick-char)))))

(defun +irc-evil-insert-h ()
  "Ensure entering insert mode will put us at the prompt, unless editing
after prompt marker."
  (when (> (marker-position lui-input-marker) (point))
    (goto-char (point-max))))

(defun +irc-preinput-scroll-to-bottom-h ()
  "Go to the end of the buffer in all windows showing it.
Courtesy of esh-mode.el"
  (when (memq this-command +irc-scroll-to-bottom-on-commands)
    (let* ((selected (selected-window))
           (current (current-buffer)))
      (when (> (marker-position lui-input-marker) (point))
        (walk-windows
         (function
          (lambda (window)
            (when (eq (window-buffer window) current)
              (select-window window)
              (goto-char (point-max))
              (select-window selected))))
         nil t)))))

(defun +irc-init-lui-margins-h ()
  (pcase lui-time-stamp-position
    (`right-margin (setq right-margin-width (length (format-time-string lui-time-stamp-format))))
    (`left-margin  (setq left-margin-width  (length (format-time-string lui-time-stamp-format))))))

(defun +irc-init-lui-wrapping-a ()
  (setq fringes-outside-margins t
        word-wrap t
        wrap-prefix (make-string (+ +irc-left-padding 3) ? )))

(leaf circe
  :ensure t
  :commands circe-server-buffers
  :config
  (setq circe-network-options
        '(("Libera.Chat"
           :tls t
           :nick "lunixose"
           :host "irc.libera.chat"
           :port 6697))
        circe-default-quit-message nil
        circe-default-part-message nil
        circe-use-cycle-completion t
        circe-reduce-lurker-spam t

        circe-format-say (format "{nick:+%ss} │ {body}" +irc-left-padding)
        circe-format-self-say circe-format-say
        circe-format-action (format "{nick:+%ss} * {body}" +irc-left-padding)
        circe-format-self-action circe-format-action
        circe-format-server-notice
        (let ((left "-Server-"))
          (concat (make-string (- +irc-left-padding (length left)) ? )
                  (concat left " _ {body}")))
        circe-format-notice (format "{nick:%ss} _ {body}" +irc-left-padding)
        circe-format-server-topic
        (+irc--pad "Topic" "{userhost}: {topic-diff}")
        circe-format-server-join-in-channel
        (+irc--pad "Join" "{nick} ({userinfo}) joined {channel}")
        circe-format-server-join
        (+irc--pad "Join" "{nick} ({userinfo})")
        circe-format-server-part
        (+irc--pad "Part" "{nick} ({userhost}) left {channel}: {reason}")
        circe-format-server-quit
        (+irc--pad "Quit" "{nick} ({userhost}) left IRC: {reason}]")
        circe-format-server-quit-channel
        (+irc--pad "Quit" "{nick} ({userhost}) left {channel}: {reason}]")
        circe-format-server-rejoin
        (+irc--pad "Re-join" "{nick} ({userhost}), left {departuredelta} ago")
        circe-format-server-netmerge
        (+irc--pad "Netmerge" "{split}, split {ago} ago (Use /WL to see who's still missing)")
        circe-format-server-nick-change
        (+irc--pad "Nick" "{old-nick} ({userhost}) is now known as {new-nick}")
        circe-format-server-nick-change-self
        (+irc--pad "Nick" "You are now known as {new-nick} ({old-nick})")
        circe-format-server-mode-change
        (+irc--pad "Mode" "{change} on {target} by {setter} ({userhost})")
        circe-format-server-lurker-activity
        (+irc--pad "Lurk" "{nick} joined {joindelta} ago"))
  ;; doom adds `circe-mode' to `doom-real-buffer-modes'; no equivalent here.
  (add-hook 'circe-channel-mode-hook #'turn-on-visual-line-mode)
  (add-hook 'circe-mode-hook #'+irc--add-circe-buffer-to-persp-h)
  (add-hook 'circe-mode-hook #'turn-off-smartparens-mode)
  (defadvice! +irc--circe-run-disconnect-hook-a (&rest _)
    :after #'circe--irc-conn-disconnected
    (run-hooks '+irc-disconnect-hook))
  (add-hook 'circe-message-option-functions #'+irc-circe-message-option-bot-h)
  ;; Let `+irc/quit' and `circe' handle buffer cleanup
  (define-key circe-mode-map [remap kill-buffer] #'bury-buffer)
  ;; Fail gracefully if not in a circe buffer
  (global-set-key [remap tracking-next-buffer] #'+irc/tracking-next-buffer)
  (when (modulep! :completion vertico)
    (with-eval-after-load 'consult
      (add-to-list 'consult-buffer-sources '+irc--consult-circe-source 'append)))
  (general-def :keymaps 'circe-mode-map :prefix doom-localleader-key
    "a" #'tracking-next-buffer
    "j" #'circe-command-JOIN
    "m" #'+irc/send-message
    "p" #'circe-command-PART
    "Q" #'+irc/quit
    "R" #'circe-reconnect
    "c" #'+irc/jump-to-channel)
  (general-def :keymaps 'circe-channel-mode-map :prefix doom-localleader-key
    "n" #'circe-command-NAMES))

;; circe-color-nicks / circe-new-day-notifier / lui / lui-logging all ship in
;; the circe distribution, so they have no separate nixpkgs emacs package.
(leaf circe-color-nicks
  :ensure nil
  :after circe
  :config
  (setq circe-color-nicks-min-constrast-ratio 4.5
        circe-color-nicks-everywhere t)
  (enable-circe-color-nicks))

(leaf circe-new-day-notifier
  :ensure nil
  :after circe
  :config
  (enable-circe-new-day-notifier)
  (setq circe-new-day-notifier-format-message
        (+irc--pad "Day" "Date changed [{day}]")))

(leaf circe-notifications
  :ensure t
  :defer t
  :init
  (add-hook 'circe-server-connected-hook #'+irc-init-circe-notifications-h)
  :config
  (setq circe-notifications-emacs-focused nil
        circe-notifications-alert-style
        (cond ((memq system-type '(darwin)) 'osx-notifier)
              ((memq system-type '(gnu gnu/linux)) 'libnotify)
              (circe-notifications-alert-style))))

(leaf lui
  :ensure nil
  :commands lui-mode
  :config
  (define-key lui-mode-map "\C-u" #'lui-kill-to-beginning-of-line)
  (setq lui-fill-type nil
        lui-flyspell-p (modulep! :checkers spell +flyspell))
  (setq lui-time-stamp-format "%H:%M"
        lui-time-stamp-position 'right-margin)
  (enable-lui-autopaste)  ; prompt to use paste service for large pastes
  (enable-lui-track)      ; horizontal line marking last read message
  (enable-lui-irc-colors) ; enable IRC colors (https://www.mirc.co.uk/colors.html)
  (add-hook 'lui-pre-output-hook #'+irc-truncate-nicks-h)
  (with-eval-after-load 'evil
    (add-hook 'lui-mode-hook
              (lambda () (add-hook 'evil-insert-state-entry-hook #'+irc-evil-insert-h nil 'local))))
  (add-hook 'lui-mode-hook
            (lambda () (add-hook 'pre-command-hook #'+irc-preinput-scroll-to-bottom-h nil t)))
  (add-hook 'lui-mode-hook #'+irc-init-lui-margins-h)
  (add-hook 'lui-mode-hook #'+irc-init-lui-wrapping-a))

(leaf lui-logging
  :ensure nil
  :after lui
  :config
  (setq lui-logging-directory (doom-profile-state-dir t "lui"))
  (enable-lui-logging))


;;; app/rss
(defcustom +rss-enable-sliced-images t
  "Automatically slice images shown in elfeed-show-mode buffers, making them
easier to scroll through."
  :type 'boolean)

(defcustom +rss-workspace-name "*rss*"
  "Name of the workspace that contains the elfeed buffer."
  :type 'string)

(defvar +rss--wconf nil)

(defun +rss/delete-pane ()
  "Delete the *elfeed-entry* split pane."
  (interactive)
  (let* ((buf (get-buffer "*elfeed-entry*"))
         (window (get-buffer-window buf)))
    (delete-window window)
    (when (buffer-live-p buf)
      (kill-buffer buf))))

(defun +rss/open (entry)
  "Display the currently selected item in a buffer."
  (interactive (list (elfeed-search-selected :ignore-region)))
  (when (elfeed-entry-p entry)
    (elfeed-untag entry 'unread)
    (elfeed-search-update-entry entry)
    (elfeed-show-entry entry)))

(defun +rss/next ()
  "Show the next item in the elfeed-search buffer."
  (interactive)
  (funcall elfeed-show-entry-delete)
  (with-current-buffer (elfeed-search-buffer)
    (forward-line)
    (call-interactively '+rss/open)))

(defun +rss/previous ()
  "Show the previous item in the elfeed-search buffer."
  (interactive)
  (funcall elfeed-show-entry-delete)
  (with-current-buffer (elfeed-search-buffer)
    (forward-line -1)
    (call-interactively '+rss/open)))

(defun +rss/copy-link ()
  "Copy current link to clipboard."
  (interactive)
  (let ((link (elfeed-entry-link elfeed-show-entry)))
    (when link
      (kill-new link)
      (message "Copied %s to clipboard" link))))

(defun +rss-elfeed-wrap-h ()
  "Enhances an elfeed entry's readability by wrapping it to a width of
`fill-column'."
  (let ((inhibit-read-only t)
        (inhibit-modification-hooks t))
    (setq-local truncate-lines nil)
    (setq-local shr-use-fonts nil)
    (setq-local shr-width 85)
    (set-buffer-modified-p nil)))

(defun +rss--cleanup-on-kill-h ()
  "Run `elfeed-db-compact'. See `+rss-cleanup-h'."
  ;; `delete-file-projectile-remove-from-cache' slows down `elfeed-db-compact'
  ;; tremendously, so we disable the projectile cache:
  (let (projectile-enable-caching)
    (elfeed-db-compact)))

(defun +rss-cleanup-h ()
  "Clean up after an elfeed session. Kills all elfeed and elfeed-org files."
  (interactive)
  (add-hook 'kill-emacs-hook #'+rss--cleanup-on-kill-h)
  (let ((buf (previous-buffer)))
    (when (or (null buf) (not (doom-real-buffer-p buf)))
      (switch-to-buffer (doom-fallback-buffer))))
  (let ((search-buffers (cl-loop for b in (buffer-list)
                                 if (with-current-buffer b
                                      (derived-mode-p 'elfeed-search-mode))
                                 collect b))
        (show-buffers (cl-loop for b in (buffer-list)
                               if (with-current-buffer b
                                    (derived-mode-p 'elfeed-show-mode))
                               collect b))
        kill-buffer-query-functions)
    (dolist (file (bound-and-true-p rmh-elfeed-org-files))
      (when-let* ((buf (get-file-buffer (expand-file-name
                                         file
                                         (or (bound-and-true-p org-directory)
                                             default-directory)))))
        (kill-buffer buf)))
    (dolist (b search-buffers)
      (with-current-buffer b
        (remove-hook 'kill-buffer-hook #'+rss-cleanup-h :local)
        (kill-buffer b)))
    (mapc #'kill-buffer show-buffers))
  (when (window-configuration-p +rss--wconf)
    (set-window-configuration +rss--wconf))
  (setq +rss--wconf nil)
  (previous-buffer))

(defun +rss-dead-feeds (&optional years)
  "Return a list of feeds that haven't posted anything in YEARS."
  (let* ((years (or years 1.0))
         (living-feeds (make-hash-table :test 'equal))
         (seconds (* years 365.0 24 60 60))
         (threshold (- (float-time) seconds)))
    (with-elfeed-db-visit (entry feed)
      (let ((date (elfeed-entry-date entry)))
        (when (> date threshold)
          (setf (gethash (elfeed-feed-url feed) living-feeds) t))))
    (cl-loop for url in (elfeed-feed-list)
             unless (gethash url living-feeds)
             collect url)))

(defun +rss-put-sliced-image-fn (spec alt &optional flags)
  "Insert images sliced so they scroll smoothly."
  (cl-letf (((symbol-function 'insert-image)
             (lambda (image &optional alt _area _slice)
               (let ((height (cdr (image-size image t))))
                 (insert-sliced-image image alt nil (max 1 (/ height 20.0)) 1)))))
    (shr-put-image spec alt flags)))

(defun +rss-render-image-tag-without-underline-fn (dom &optional url)
  "Render an image tag and strip any underline face."
  (let ((start (point)))
    (shr-tag-img dom url)
    ;; And remove underlines in case images are links, otherwise we get an
    ;; underline beneath every slice.
    (put-text-property start (point) 'face '(:underline nil))))

(defun =rss ()
  "Activate (or switch to) the elfeed RSS reader."
  (interactive)
  (if-let* ((buf (cl-loop for b in (buffer-list)
                          if (with-current-buffer b
                               (derived-mode-p 'elfeed-search-mode))
                          return b)))
      (switch-to-buffer buf)
    (elfeed)))

(leaf elfeed
  :ensure t
  :commands elfeed
  :config
  (setq elfeed-db-directory (doom-profile-data-dir t "elfeed" "db/")
        elfeed-enclosure-default-dir (doom-profile-data-dir t "elfeed" "enclosures/")
        elfeed-search-filter "@2-week-ago "
        elfeed-show-entry-switch #'pop-to-buffer
        elfeed-show-entry-delete #'+rss/delete-pane
        shr-max-image-proportion 0.8)
  (make-directory elfeed-db-directory t)
  ;; doom adds elfeed buffers to `doom-real-buffer-functions'; no equivalent.
  (add-hook 'elfeed-show-mode-hook #'+rss-elfeed-wrap-h)
  (add-hook 'elfeed-search-mode-hook
            (lambda () (add-hook 'kill-buffer-hook #'+rss-cleanup-h nil 'local)))
  ;; Large images are annoying to scroll through, because scrolling follows the
  ;; cursor, so we force shr to insert images in slices.
  (when +rss-enable-sliced-images
    (add-hook 'elfeed-show-mode-hook
              (lambda ()
                (setq-local shr-put-image-function #'+rss-put-sliced-image-fn)
                (setq-local shr-external-rendering-functions
                            '((img . +rss-render-image-tag-without-underline-fn))))))
  (with-eval-after-load 'elfeed-show
    (define-key elfeed-show-mode-map [remap next-buffer] #'+rss/next)
    (define-key elfeed-show-mode-map [remap previous-buffer] #'+rss/previous))
  (when (modulep! :editor evil +everywhere)
    (evil-define-key 'normal elfeed-search-mode-map
      "q" #'kill-current-buffer
      "r" #'revert-buffer
      (kbd "M-RET") #'elfeed-search-browse-url)
    (map! :map elfeed-show-mode-map
          :n "gc" nil
          :n "gc" #'+rss/copy-link)))
;; `+rss--fix-elfeed-search-selected-off-by-one-a' (an evil visual-line fix)
;; needs doom's `letf!'; dropped.

(leaf elfeed-org
  :ensure t
  :after elfeed
  ;; doom gates this on `+org`, which the compat resolves to nil, but the task
  ;; requires elfeed-org, so it is declared unconditionally.
  :config
  (setq rmh-elfeed-org-files (list "elfeed.org"))
  (elfeed-org)
  (defadvice! +rss-skip-missing-org-files-a (&rest _)
    :before '(elfeed rmh-elfeed-org-mark-feed-ignore elfeed-org-export-opml)
    (unless (file-name-absolute-p (car rmh-elfeed-org-files))
      (let* ((default-directory (or (bound-and-true-p org-directory)
                                    default-directory))
             (files (mapcar #'expand-file-name rmh-elfeed-org-files)))
        (dolist (file (cl-remove-if #'file-exists-p files))
          (message "elfeed-org: ignoring %S because it can't be read" file))
        (setq rmh-elfeed-org-files (cl-remove-if-not #'file-exists-p files))))))

;; elfeed-tube: gated on `+youtube` (nil in compat); dropped.
;;; app-config.el ends here
(provide 'app-config)
