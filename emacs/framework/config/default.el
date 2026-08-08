;;; config/default.el --- doom config/default port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/config/default.
;;; Code:

;;; Reasonable defaults
(defvar +default-want-RET-continue-comments t
  "If non-nil, RET will continue commented lines.")

(defvar +default-minibuffer-maps
  (append '(minibuffer-local-map
            minibuffer-local-ns-map
            minibuffer-local-completion-map
            minibuffer-local-must-match-map
            minibuffer-local-isearch-map
            read-expression-map))
  "A list of all the keymaps used for the minibuffer.")

(leaf smartparens
  :ensure t
  :demand t
  :config
  (require 'smartparens-config)
  (smartparens-global-mode 1)
  (show-smartparens-global-mode 1))

(leaf avy
  :ensure t
  :defer t
  :config
  (avy-setup-default)
  (setq avy-all-windows nil
        avy-all-windows-alt t
        avy-background t
        ;; the unpredictability of this (when enabled) makes it a poor default
        avy-single-candidate-jump nil))

(leaf link-hint
  :ensure t
  :after avy
  :config
  (setq link-hint-avy-style 'popup-tip))

;;; Keybinding fixes (doom config/default)
;; doom core helpers, stubbed for this config.
(defun doom-point-in-string-p (&optional pos)
  "Doom-compat: non-nil if point is inside a string literal."
  (nth 3 (syntax-ppss pos)))

(defvar doom-delete-backward-functions nil
  "Doom-compat: hook run by `doom/backward-delete-whitespace-to-column'.")

(defun doom-surrounded-p (pair &optional kind strict)
  "Doom-compat: non-nil if point is surrounded by the delimiter PAIR."
  (let ((op (plist-get pair :op))
        (cl (plist-get pair :cl))
        (beg (plist-get pair :beg))
        (end (plist-get pair :end)))
    (and op cl beg end
         (eq (char-before) (aref op (1- (length op))))
         (eq (char-after) (aref cl 0)))))

(defun doom/backward-delete-whitespace-to-column ()
  "Delete back to the previous column of whitespace, or as much whitespace as
possible, or just one char if that's not possible."
  (interactive)
  (let* ((context
          (if (bound-and-true-p smartparens-mode)
              (ignore-errors (sp-get-thing))))
         (op (plist-get context :op))
         (cl (plist-get context :cl))
         open-len close-len current-column)
    (cond ;; When in strings (sp acts weird with quotes; this is the fix)
          ;; Also, skip closing delimiters
          ((and op cl
                (string= op cl)
                (and (string= (char-to-string (or (char-before) 0)) op)
                     (setq open-len (length op)))
                (and (string= (char-to-string (or (char-after) 0)) cl)
                     (setq close-len (length cl))))
           (delete-char (- open-len))
           (delete-char close-len))

          ;; Delete up to the nearest tab column IF only whitespace between
          ;; point and bol.
          ((and (not indent-tabs-mode)
                (> tab-width 1)
                (not (bolp))
                (not (doom-point-in-string-p))
                (>= (abs (save-excursion (skip-chars-backward " \t")))
                    (setq current-column (current-column))))
           (delete-char (- (1+ (% (1- current-column) tab-width)))))

          ;; Otherwise do a regular delete
          ((delete-char -1)))))

(defun +default--delete-backward-char-a (n &optional killflag)
  "Same as `delete-backward-char', but performs these additional checks:

+ If point is surrounded by (balanced) whitespace and a brace delimiter, delete
  a space on either side of the cursor.
+ If point is at BOL and surrounded by braces on adjacent lines, collapse
  newlines.
+ Otherwise, resort to `doom/backward-delete-whitespace-to-column'.
+ Resorts to `delete-char' if n > 1"
  (interactive "p\nP")
  (or (integerp n)
      (signal 'wrong-type-argument (list 'integerp n)))
  (cond ((and (use-region-p)
              delete-active-region
              (= n 1))
         ;; If a region is active, kill or delete it.
         (if (eq delete-active-region 'kill)
             (kill-region (region-beginning) (region-end) 'region)
           (funcall region-extract-function 'delete-only)))
        ;; In Overwrite mode, maybe untabify while deleting
        ((null (or (null overwrite-mode)
                   (<= n 0)
                   (memq (char-before) '(?\t ?\n))
                   (eobp)
                   (eq (char-after) ?\n)))
         (let ((ocol (current-column)))
           (delete-char (- n) killflag)
           (save-excursion
             (insert-char ?\s (- ocol (current-column)) nil))))
        ;;
        ((= n 1)
         (cond ((or (modulep! -smartparens)
                    (not (bound-and-true-p smartparens-mode))
                    (and (memq (char-before) (list ?\  ?\t))
                         (save-excursion
                           (and (/= (skip-chars-backward " \t" (line-beginning-position)) 0)
                                (bolp)))))
                (doom/backward-delete-whitespace-to-column))
               ((let* ((pair (ignore-errors (sp-get-thing)))
                       (op   (plist-get pair :op))
                       (cl   (plist-get pair :cl))
                       (beg  (plist-get pair :beg))
                       (end  (plist-get pair :end)))
                  (cond ((and end beg (= end (+ beg (length op) (length cl))))
                         (delete-char (- (length op))))
                        ((doom-surrounded-p pair 'inline 'balanced)
                         (delete-char -1 killflag)
                         (delete-char 1)
                         (when (= (point) (+ (length cl) beg))
                           (sp-backward-delete-char 1)
                           (sp-insert-pair op)))
                        ((and (bolp) (doom-surrounded-p pair nil 'balanced))
                         (delete-region beg end)
                         (sp-insert-pair op)
                         t)
                        ((run-hook-with-args-until-success 'doom-delete-backward-functions))
                        ((doom/backward-delete-whitespace-to-column)))))))
        ;; Otherwise, do simple deletion.
        ((delete-char (- n) killflag))))

;; Highjacks backspace to delete up to nearest column multiple of `tab-width' at
;; a time. If you have smartparens enabled, it will also balance spaces inside
;; brackets, close empty multiline brace blocks in one step, refresh
;; smartparens' :post-handlers, properly delete smartparen pairs, and do none
;; of this when inside a string.
(advice-add #'delete-backward-char :override #'+default--delete-backward-char-a)

;; HACK: Makes `newline-and-indent' continue comments (and more reliably).
;;   Consults `luna-point-in-comment-p' to detect a commented region and uses
;;   that mode's `comment-line-break-function' to continue comments.
(defadvice! +default--newline-indent-and-continue-comments-a (&rest _)
  :before-until #'newline-and-indent
  (interactive "*")
  (when (and (or (not (bound-and-true-p electric-indent-mode))
                 (bound-and-true-p electric-indent-inhibit))
             +default-want-RET-continue-comments
             (luna-point-in-comment-p)
             (functionp comment-line-break-function))
    (funcall comment-line-break-function nil)
    t))

;; Consistently use q to quit windows
(after! tabulated-list
  (define-key tabulated-list-mode-map "q" #'quit-window))

;;; gnupg (doom config/default; inert while the +gnupg flag resolves nil)
(when (modulep! +gnupg)
  ;; By default, Emacs stores `authinfo' in $HOME and in plain-text. Let's not
  ;; do that, mkay? This file stores usernames, passwords, and other treasures
  ;; for the aspiring malicious third party. You'll need a GPG setup though.
  (setq auth-sources (list (luna-profile-state-dir t "authinfo.gpg")
                           "~/.authinfo.gpg"))

  (after! epa
    ;; With GPG 2.1+, this forces gpg-agent to use the Emacs minibuffer to
    ;; prompt for the key passphrase.
    (set 'epg-pinentry-mode 'loopback)
    ;; Default to the first enabled and non-expired key in your keyring.
    (setq-default
     epa-file-encrypt-to
     (or (default-value 'epa-file-encrypt-to)
         (unless (string-empty-p user-full-name)
           (when-let* ((context (ignore-errors (epg-make-context))))
             (cl-loop for key in (epg-list-keys context user-full-name 'public)
                      for subkey = (car (epg-key-sub-key-list key))
                      if (not (memq 'disabled (epg-sub-key-capability subkey)))
                      if (< (or (epg-sub-key-expiration-time subkey) 0)
                            (time-to-seconds))
                      collect (epg-sub-key-fingerprint subkey))))
         user-mail-address))
    ;; And suppress prompts if epa-file-encrypt-to has a default value (without
    ;; overwriting file-local values).
    (defadvice! +default--dont-prompt-for-keys-a (&rest _)
      :before #'epa-file-write-region
      (unless (local-variable-p 'epa-file-encrypt-to)
        (setq-local epa-file-encrypt-to (default-value 'epa-file-encrypt-to))))))

(after! woman
  ;; The woman-manpath default value does not necessarily match man. If we have
  ;; man available but aren't using it for performance reasons, we can extract
  ;; its manpath.
  (when-let* ((path (cond
                     ((executable-find "manpath")
                      (split-string (cdr (luna-call-process "manpath" "-q"))
                                    path-separator t))
                     ((executable-find "man")
                      (split-string (cdr (luna-call-process "man" "--path"))
                                    path-separator t)))))
    (setq woman-manpath path)))

;;; Bootstrap configs (doom config/default)
(when (modulep! :editor evil)
  (defun +default-disable-delete-selection-mode-h ()
    (delete-selection-mode -1))
  (add-hook 'evil-insert-state-entry-hook #'delete-selection-mode)
  (add-hook 'evil-insert-state-exit-hook #'+default-disable-delete-selection-mode-h)

  ;; Make SPC u SPC u [...] possible (doomemacs/core#747)
  (general-def :keymaps 'universal-argument-map :prefix luna-leader-key
    "u" #'universal-argument-more))

;; The +bindings branches and the non-evil bootstrap branch (drag-stuff,
;; expand-region) are keybinding-specific or dead (evil is enabled); skipped.

;;; config/default.el ends here
