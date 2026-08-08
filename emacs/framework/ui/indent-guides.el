;;; ui/indent-guides.el --- doom ui/indent-guides port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/indent-guides.
;;; Code:

;;; :ui indent-guides
(defcustom +indent-guides-inhibit-functions ()
  "A list of predicate functions.

Each function will be run in the context of a buffer where `indent-bars' should
be enabled. If any function returns non-nil, the mode will not be activated."
  :type 'hook
  :group 'indent-guides)

(leaf indent-bars
  :ensure t
  :defer t
  :init
  (defun +indent-guides-startup-h ()
    "Set up indent-bars to activate after startup."
    (add-hook 'after-change-major-mode-hook #'+indent-guides-init-maybe-h 95))

  (defun +indent-guides-init-maybe-h ()
    "Enable `indent-bars-mode' depending on `+indent-guides-inhibit-functions'."
    (unless (or (eq major-mode 'fundamental-mode)
                (luna-temp-buffer-p (current-buffer))
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
  ;; which will be redundant with `luna-load-theme-hook'.
  (unless (boundp 'enable-theme-functions)
    (add-hook 'luna-load-theme-hook #'indent-bars-reset-styles))

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

;; APROX: doom hooked `luna-first-buffer' (a no-op hook in the compat layer);
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

;;; ui/indent-guides.el ends here
