;;; app/irc.el --- doom app/irc port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/app/irc.
;;; Code:

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
  (general-def :keymaps 'circe-mode-map :prefix luna-localleader-key
    "a" #'tracking-next-buffer
    "j" #'circe-command-JOIN
    "m" #'+irc/send-message
    "p" #'circe-command-PART
    "Q" #'+irc/quit
    "R" #'circe-reconnect
    "c" #'+irc/jump-to-channel)
  (general-def :keymaps 'circe-channel-mode-map :prefix luna-localleader-key
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
  (setq lui-logging-directory (luna-profile-state-dir t "lui"))
  (enable-lui-logging))

;;; app/irc.el ends here
