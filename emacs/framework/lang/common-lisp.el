;;; lang/common-lisp.el --- doom lang/common-lisp port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/common-lisp.
;;; Code:

;;; lang/common-lisp
;; doom's lang/common-lisp is built on sly. The task brief said 'slime', but
;; the doom module config is entirely sly-flavoured and sly is available in
;; nixpkgs, so sly is ported as-is.

(defcustom +lisp-quicklisp-paths '("~/quicklisp" "~/.quicklisp")
  "A list of directories to search for Quicklisp's site files."
  :type '(repeat directory))

(defvar inferior-lisp-program "sbcl")

;; HACK: Fix doomemacs/core#1772: void-variable sly-contribs errors due to sly
;;   packages (like `sly-macrostep') trying to add to `sly-contribs' before it
;;   is defined.
(defvar sly-contribs '(sly-fancy))

;;;###package macrostep-expand
(defun +lisp/open-repl ()
  "Open the Sly REPL."
  (interactive)
  (require 'sly)
  (if (sly-connected-p) (sly-mrepl)
    (sly nil nil t)
    (cl-labels ((recurse (attempt)
                  (sleep-for 1)
                  (cond ((sly-connected-p) (sly-mrepl))
                        ((> attempt 5) (error "Failed to start Slynk process."))
                        (t (recurse (1+ attempt))))))
      (recurse 1))))

(defun +lisp/reload-project ()
  "Restart the Sly session and reload a chosen system."
  (interactive)
  (require 'sly-asdf)
  (sly-restart-inferior-lisp)
  (cl-labels ((recurse (attempt)
                (sleep-for 1)
                (condition-case nil
                    (sly-eval "PONG")
                  (error (if (= 5 attempt)
                             (error "Failed to reload Lisp project in 5 attempts.")
                           (recurse (1+ attempt)))))))
    (recurse 1)
    (sly-asdf-load-system
     (or (sly-asdf-find-current-system)
         (car sly-asdf-system-history)
         (user-error "Can't find a system to reload")))))

(defun +lisp/find-file-in-quicklisp ()
  "Find a file belonging to a library downloaded by Quicklisp."
  (interactive)
  (let ((dir (or (cl-loop for d in +lisp-quicklisp-paths
                          if (file-directory-p d)
                          return (expand-file-name "dists/" d))
                 (user-error "Couldn't find your Quicklisp directory (customize `+lisp-quicklisp-paths')"))))
    (find-file (read-file-name "Find file in Quicklisp: " dir))))

(leaf sly
  :ensure t
  :hook (lisp-mode . sly-editing-mode)
  :init
  ;; `sly-editing-mode' is autoloaded by sly and also added to lisp-mode-hook,
  ;; so the :hook above would enable it twice; remove the autoloaded copy once
  ;; sly loads.
  (with-eval-after-load 'sly
    (remove-hook 'lisp-mode-hook #'sly-editing-mode))
  ;; This needs to be appended so it fires later than `sly-editing-mode'
  (add-hook 'lisp-mode-hook #'sly-lisp-indent-compatibility-mode 'append)
  ;; HACK: Ensures sly's contrib modules are loaded as soon as possible, but
  ;;   also as late as possible, so users have an opportunity to override
  ;;   `sly-contrib' in an `after!' block.
  (add-hook 'after-init-hook
            (lambda () (with-eval-after-load 'sly (sly-setup))))
  :config
  (setq sly-mrepl-history-file-name (luna-profile-cache-dir t "sly-mrepl-history")
        sly-kill-without-query-p t
        sly-net-coding-system 'utf-8-unix
        ;; doom defaults to non-fuzzy search, because it is faster and more
        ;; precise (but requires more keystrokes). Change this to
        ;; `sly-flex-completions' for fuzzy completion
        sly-complete-symbol-function 'sly-simple-completions)

  ;; HACK: When there are no completion matches, all candidates are displayed.
  ;;   Very disruptive for users with idle completion on.
  ;; REVIEW: Remove when joaotavora/sly#705 is resolved.
  (defadvice! +common-lisp--suppress-all-completions-on-empty-prefix-a (fn prefix)
    :around #'sly-simple-completions
    (if (equal prefix "")
        (list nil "")
      (funcall fn prefix)))

  (defun +common-lisp--cleanup-sly-maybe-h ()
    "Kill processes and leftover buffers when killing the last sly buffer."
    (unless (cl-loop for buf in (delq (current-buffer) (buffer-list))
                     if (and (buffer-local-value 'sly-mode buf)
                             (get-buffer-window buf))
                     return t)
      (dolist (conn (sly--purge-connections))
        (sly-quit-lisp-internal conn 'sly-quit-sentinel t))
      (let (kill-buffer-hook kill-buffer-query-functions)
        (mapc #'kill-buffer
              (cl-loop for buf in (delq (current-buffer) (buffer-list))
                       if (buffer-local-value 'sly-mode buf)
                       collect buf)))))

  (add-hook 'sly-mode-hook #'+common-lisp-init-sly-h)

  (when (modulep! :editor evil +everywhere)
    (add-hook 'sly-mode-hook #'evil-normalize-keymaps)))

(defun +common-lisp-init-sly-h ()
  "Attempt to auto-start sly when opening a lisp buffer."
  (cond ((or (luna-temp-buffer-p (current-buffer))
             (sly-connected-p)))
        ((executable-find (car (if (listp inferior-lisp-program)
                                   inferior-lisp-program
                                 (split-string inferior-lisp-program))))
         (let ((sly-auto-start 'always))
           (sly-auto-start)
           (add-hook 'kill-buffer-hook #'+common-lisp--cleanup-sly-maybe-h nil t)))
        ((message "WARNING: Couldn't find `inferior-lisp-program' (%s)"
                  inferior-lisp-program))))

(leaf sly-repl-ansi-color
  :ensure t
  :defer t
  :init
  (add-to-list 'sly-contribs 'sly-repl-ansi-color))

(leaf sly-asdf
  :ensure t
  :defer t
  :init
  (add-to-list 'sly-contribs 'sly-asdf 'append))

(leaf sly-macrostep
  :ensure t
  :defer t
  :init
  (add-to-list 'sly-contribs 'sly-macrostep 'append))

;; sly-stepper: no nixpkgs emacs package; dropped.

;;; lang/common-lisp.el ends here