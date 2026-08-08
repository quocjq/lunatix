;;; completion/completion.el --- doom :completion group file  -*- lexical-binding: t; -*-
;;; Module files in this dir are gated by `(modulep! :completion <module>)';
;;; this group file always loads first.

;;; completion-config.el --- vertico/consult/corfu stack, doom :completion  -*- lexical-binding: t; -*-

;; dlet shim (doom-compat gap): dynamic let with optional overrides
(defmacro dlet (bindings &rest body)
  (declare (indent 1))
  `(let ,(mapcar (lambda (b) (if (symbolp b) (list b nil) b)) bindings)
     ,@(mapcar (lambda (b) (unless (symbolp b) `(set ,(car b) ,(cadr b)))) bindings)
     ,@body))

;; doom completion/corfu vars
(defcustom +corfu-want-ret-to-confirm t
  "t: insert if selected, passthrough otherwise; nil: passthrough; both: both."
  :type '(choice (const t) (const nil) (const both) (const minibuffer)))
(defcustom +corfu-buffer-scanning-size-limit (* 1 1024 1024)
  "Size limit for buffers scanned by `cape-dabbrev'."
  :type 'integer)
(defcustom +corfu-want-minibuffer-completion t
  "Whether to enable Corfu in the minibuffer."
  :type '(choice (const nil) (const aggressive) (const t)))
(defcustom +corfu-inhibit-auto-functions ()
  "Predicates that inhibit `corfu-auto'."
  :type 'hook)

;; doom completion/corfu autoload helpers (copied)
(defun +corfu-dabbrev-friend-buffer-p (other-buffer)
  (< (buffer-size other-buffer) +corfu-buffer-scanning-size-limit))

(defun +corfu/move-to-minibuffer ()
  "Move list of candidates to your choice of minibuffer completion UI."
  (interactive)
  (unless completion-in-region--data
    (user-error "No completion active"))
  (pcase-let ((`(,beg ,end ,table ,pred ,extras) completion-in-region--data))
    (let ((completion-extra-properties extras)
          completion-cycle-threshold
          completion-cycling)
      (cond ((and (fboundp #'consult-completion-in-region))
             (consult-completion-in-region beg end table pred))
            ((user-error "No minibuffer completion UI available for moving to!"))))))

(defun +corfu/smart-sep-toggle-escape ()
  "Insert `corfu-separator' or toggle escape if it's already there."
  (interactive)
  (cond ((and (char-equal (char-before) corfu-separator)
              (char-equal (char-before (1- (point))) ?\\))
         (save-excursion (delete-char -2)))
        ((char-equal (char-before) corfu-separator)
         (save-excursion (backward-char 1) (insert-char ?\\)))
        ((call-interactively #'corfu-insert-separator))))

(defun +corfu/dabbrev-this-buffer ()
  "Like `cape-dabbrev', but only scans current buffer."
  (interactive)
  (require 'cape)
  (let ((cape-dabbrev-buffer-function #'current-buffer))
    (cape-dabbrev t)))

(defun +corfu/toggle-auto-complete (&optional interactive)
  "Toggle as-you-type completion in Corfu."
  (interactive (list 'interactive))
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when corfu-mode
        (if corfu-auto
            (remove-hook 'post-command-hook #'corfu-auto--post-command 'local)
          (add-hook 'post-command-hook #'corfu-auto--post-command nil 'local)))))
  (when interactive
    (message "Corfu auto-complete %s" (if corfu-auto "disabled" "enabled")))
  (setq corfu-auto (not corfu-auto)))

(defun +corfu/dabbrev-or-next (&optional arg)
  "Invoke `cape-dabbrev' but respect `evil-complete-all-buffers'."
  (interactive "p")
  (if corfu--candidates
      (corfu-next arg)
    (require 'cape)
    (let ((cape-dabbrev-buffer-function
           (if (bound-and-true-p evil-complete-all-buffers)
               #'cape-same-mode-buffers
             #'current-buffer)))
      (cape-dabbrev t)
      (when (> corfu--total 0)
        (corfu--goto (or arg 0))))))

(defun +corfu/dabbrev-or-last (&optional arg)
  "Invoke `cape-dabbrev' but respect `evil-complete-all-buffers'."
  (interactive "p")
  (if corfu--candidates
      (corfu-previous arg)
    (require 'cape)
    (let ((cape-dabbrev-buffer-function
           (if (bound-and-true-p evil-complete-all-buffers)
               #'cape-same-mode-buffers
             #'current-buffer)))
      (cape-dabbrev t)
      (when (> corfu--total 0)
        (corfu--goto (- corfu--total (or arg 1)))))))

;; doom completion/vertico autoload helpers (copied)
(defun +vertico-orderless-dispatch (pattern _index _total)
  "Like `orderless-affix-dispatch', but allows affixes to be escaped."
  (let ((len (length pattern))
        (alist orderless-affix-dispatch-alist))
    (when (> len 0)
      (cond
       ((and (= len 1) (alist-get (aref pattern 0) alist)) #'ignore)
       ((when-let* ((style (alist-get (aref pattern 0) alist))
                    ((not (char-equal (aref pattern (max (1- len) 1)) ?\\))))
          (cons style (substring pattern 1))))
       ((when-let* ((style (alist-get (aref pattern (1- len)) alist))
                    ((not (char-equal (aref pattern (max 0 (- len 2))) ?\\))))
          (cons style (substring pattern 0 -1))))))))

(defun +vertico-orderless-disambiguation-dispatch (pattern _index _total)
  "Disambiguation dispatch for orderless."
  (cond
   ((string-prefix-p "!" pattern) (cons 'orderless-without-literal (substring pattern 1)))
   ((string-prefix-p "=" pattern) (cons 'orderless-literal (substring pattern 1)))))

(defun +vertico-crm-indicator (args)
  "CRM indicator wrapper for `completing-read-multiple'."
  (cons (format "[CRM%s] %s"
                (replace-regexp-in-string "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" "" crm-separator)
                (car args))
        (cdr args)))

(defun +vertico/enter-or-preview ()
  "Enter directory or embark preview on current candidate."
  (interactive)
  (when (> 0 vertico--index)
    (user-error "No vertico session is currently active"))
  (if (and (let ((cand (vertico--candidate)))
             (or (string-suffix-p "/" cand)
                 (and (vertico--remote-p cand)
                      (string-suffix-p ":" cand))))
           (not (equal vertico--base ""))
           (eq 'file (vertico--metadata-get 'category)))
      (vertico-insert)
    (condition-case _ (+vertico/embark-preview)
      ('error (vertico-insert)))))

(defun +vertico/embark-preview ()
  "Previews candidate in vertico buffer, unless it's a consult command."
  (interactive)
  (unless (bound-and-true-p consult--preview-function)
    (unless (require 'embark nil t)
      (user-error "Embark not installed, aborting..."))
    (save-selected-window
      (dlet (embark-quit-after-action)
        (embark-dwim)))))

(defun +vertico/jump-list (jump)
  "Go to an entry in evil's (or better-jumper's) jumplist."
  (interactive
   (let (buffers)
     (require 'consult)
     (unwind-protect
         (list (consult--read
                (nreverse (delete-dups (delq nil (mapcar (lambda (pt) (marker-buffer pt))
                                                         evil--jumps))))
                :prompt "Jump to:"
                :sort nil :require-match t))
       (setq evil--jumps (cons (point-marker) evil--jumps)))))
  (when-let* ((marker (seq-find (lambda (pt) (equal (marker-buffer pt) (current-buffer)))
                                evil--jumps)))
    (goto-char marker)))

;;; Packages

;;; completion/completion.el ends here
