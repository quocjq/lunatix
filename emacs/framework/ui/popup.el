;;; ui/popup.el --- doom ui/popup port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/popup.
;;; Code:

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
  (and (boundp 'popper-reference-buffers) popper-reference-buffers))

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
  (let ((buf (current-buffer))
        (pred (lambda (b) (eq b buf))))
    (if (boundp 'popper-reference-buffers)
        (add-to-list 'popper-reference-buffers pred)
      (with-eval-after-load 'popper
        (add-to-list 'popper-reference-buffers pred)))
    (when (and popper-mode (fboundp 'popper--set-reference-vars))
      (popper--set-reference-vars))
    (popper-toggle)))

(leaf popper
  :ensure t
  :defer t
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

;;; ui/popup.el ends here
