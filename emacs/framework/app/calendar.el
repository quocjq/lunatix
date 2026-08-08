;;; app/calendar.el --- doom app/calendar port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/app/calendar.
;;; Code:

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
  (when (modulep! :editor evil +everywhere)
    (evil-set-initial-state 'calfw-calendar-mode 'motion)
    (evil-set-initial-state 'calfw-details-mode 'motion)
    (add-hook 'calfw-calendar-mode-hook #'evil-normalize-keymaps)
    (add-hook 'calfw-details-mode-hook #'evil-normalize-keymaps))
(add-hook 'calfw-calendar-mode-hook #'luna-mark-buffer-as-real-h)
  ;; mode-line-invisible-mode (doom :ui mode-line) has no equivalent here.
  (add-hook 'calfw-calendar-mode-hook #'luna-disable-line-numbers-h)
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

;; org-gcal dropped: it needs a Google Calendar API client-id/secret the user
;; must set (org-gcal-client-id/org-gcal-client-secret + token.gpg). Without
;; them it just warns on load. Re-add + set creds if Google Calendar is wanted.
;;; app/calendar.el ends here
