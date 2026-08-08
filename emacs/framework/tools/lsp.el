;;; tools/lsp.el --- doom tools/lsp port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/tools/lsp. Uses the lunatix-doom compat layer.
;;; Code:

(leaf lsp-mode
  :ensure t
  :commands (lsp lsp-deferred lsp-install-server)
  :init
  ;; Don't touch ~/.emacs.d, which could be purged without warning.
  (setq lsp-session-file (expand-file-name "lsp-session-v1" (luna-profile-cache-dir))
        lsp-server-install-dir (expand-file-name "lsp/" (luna-profile-data-dir)))
  ;; Don't auto-kill LSP server after last workspace buffer is killed.
  (setq lsp-keep-workspace-alive nil)
  ;; Don't prompt "Select project" on every new file; auto-use the detected
  ;; project root (session-file corruption made every project look new).
  (setq lsp-ask-about-project-root nil)

  ;; Disable expensive/impressive features; make them opt-in.
  (setq lsp-enable-folding nil
        lsp-enable-text-document-color nil)
  (setq lsp-enable-on-type-formatting nil)
  (setq lsp-headerline-breadcrumb-enable nil)

  :config
  (set-debug-var! 'lsp-log-io t 2)

  (setq lsp-intelephense-storage-path (luna-profile-data-dir t "lsp-intelephense/")
        lsp-vetur-global-snippets-dir
        (expand-file-name
         "vetur" (or (bound-and-true-p +snippets-dir)
                     (file-name-concat (luna-user-dir) "snippets/")))
        lsp-xml-jar-file (expand-file-name "org.eclipse.lsp4xml-0.3.0-uber.jar" lsp-server-install-dir)
        lsp-groovy-server-file (expand-file-name "groovy-language-server-all.jar" lsp-server-install-dir))

  (defun +lsp-signature-stop-maybe-h ()
    "Close the displayed `lsp-signature'."
    (when lsp-signature-mode
      (lsp-signature-stop)
      t))
  (add-hook 'luna-escape-hook #'+lsp-signature-stop-maybe-h)

  (set-lookup-handlers! 'lsp-mode
    :definition #'+lsp-lookup-definition-handler
    :references #'+lsp-lookup-references-handler
    :documentation '(lsp-describe-thing-at-point :async t)
    :implementations '(lsp-find-implementation :async t)
    :type-definition #'lsp-find-type-definition)

  ;; terraform module not ported; always drop its client.
  (setq lsp-client-packages (delete 'lsp-terraform lsp-client-packages))

  (defadvice! +lsp--respect-user-defined-checkers-a (fn &rest args)
    :around #'lsp-diagnostics-flycheck-enable
    (if (and (boundp 'flycheck-checker) flycheck-checker)
        (let ((old-checker flycheck-checker))
          (apply fn args)
          (setq-local flycheck-checker old-checker))
      (apply fn args)))

  (add-hook 'lsp-before-initialize-hook #'+lsp-optimization-mode)
  (defun +lsp--disable-optimization-mode-if-no-workspaces-h (_workspace)
    (unless (lsp--session-workspaces lsp--session)
      (+lsp-optimization-mode -1)))
  (add-hook 'lsp-after-uninitialized-functions #'+lsp--disable-optimization-mode-if-no-workspaces-h)

  (defvar +lsp--deferred-shutdown-timer nil)
  ;; Defer server shutdown for a few seconds.
  (defadvice! +lsp-defer-server-shutdown-a (fn &optional restart)
    :around #'lsp--shutdown-workspace
    (if (or lsp-keep-workspace-alive
            restart
            (null +lsp-defer-shutdown)
            (= +lsp-defer-shutdown 0))
        (funcall fn restart)
      (when (timerp +lsp--deferred-shutdown-timer)
        (cancel-timer +lsp--deferred-shutdown-timer))
      (setq +lsp--deferred-shutdown-timer
            (run-at-time
             (if (numberp +lsp-defer-shutdown) +lsp-defer-shutdown 3)
             nil (lambda (workspaces)
                   (dolist (ws workspaces)
                     (or (cl-some #'lsp-buffer-live-p
                                  (lsp--workspace-buffers ws))
                         (with-lsp-workspace ws
                           (let ((lsp-restart 'ignore))
                             (funcall fn))))))
             lsp--buffer-workspaces))))

  (when (modulep! :completion corfu)
    (setq lsp-completion-provider :none)
    (add-hook 'lsp-mode-hook #'lsp-completion-mode)))

(leaf lsp-ui
  :ensure t
  :after lsp-mode
  :hook (lsp-mode . lsp-ui-mode)
  :init
  ;; Change `lsp--auto-configure' to not force `lsp-ui-mode' on us.
  (defadvice! +lsp--use-hook-instead-a (fn &rest args)
    :around #'lsp--auto-configure
    (letf! ((#'lsp-ui-mode #'ignore))
      (apply fn args)))
  :config
  (setq lsp-ui-peek-enable nil
        lsp-ui-doc-max-height 8
        lsp-ui-doc-max-width 72         ; 150 (default) is too wide
        lsp-ui-doc-delay 0.75           ; 0.2 (default) is too naggy
        lsp-ui-doc-show-with-mouse nil  ; don't disappear on mouseover
        lsp-ui-doc-position 'at-point
        lsp-ui-sideline-ignore-duplicate t
        ;; Don't show symbol definitions in the sideline (noisy, and bugs with
        ;; flycheck error display).
        lsp-ui-sideline-show-hover nil
        lsp-ui-sideline-actions-icon lsp-ui-sideline-actions-icon-default)

  (define-key lsp-ui-peek-mode-map "j"   #'lsp-ui-peek--select-next)
  (define-key lsp-ui-peek-mode-map "k"   #'lsp-ui-peek--select-prev)
  (define-key lsp-ui-peek-mode-map (kbd "C-k") #'lsp-ui-peek--select-prev-file)
  (define-key lsp-ui-peek-mode-map (kbd "C-j") #'lsp-ui-peek--select-next-file))

(leaf consult-lsp
  :ensure t
  :defer t
  :after lsp-mode
  :init
  (after! lsp-mode
    (map! :map lsp-mode-map [remap xref-find-apropos] #'consult-lsp-symbols)))

;;
;;; tools/magit (+forge, evil-collection integration)

(defvar +magit-open-windows-in-direction 'right
  "What direction to open new windows from the status buffer.")

(defvar +magit-fringe-size '(13 . 1)
  "Size of the fringe in magit-mode buffers.")

(defvar +magit-auto-revert 'local
  "If non-nil, revert associated buffers after Git operations with side-effects.")

;; Gimp `magit-version' so it doesn't complain in sparse clones.
(defadvice! +magit--ignore-version-a (fn &rest args)
  :around #'magit-version
  (let ((inhibit-message (not (called-interactively-p 'any))))
    (apply fn args)))

(defun +magit-display-buffer-fn (buffer)
  "Display magit buffers sensibly: reuse windows, split below, etc."
  (let ((buffer-mode (buffer-local-value 'major-mode buffer)))
    (display-buffer
     buffer (cond
             ((and (eq buffer-mode 'magit-status-mode)
                   (get-buffer-window buffer))
              '(display-buffer-reuse-window))
             ((or
               (bound-and-true-p git-commit-mode)
               (eq buffer-mode 'magit-process-mode)
               (eq major-mode 'magit-log-select-mode))
              (let ((size (if (eq buffer-mode 'magit-process-mode)
                              0.35
                            0.7)))
                `(display-buffer-below-selected
                  . ((window-height . ,(truncate (* (window-height) size)))))))
             ((or
               (not (derived-mode-p 'magit-mode))
               (and (eq major-mode 'magit-status-mode)
                    (memq buffer-mode
                          '(magit-diff-mode
                            magit-stash-mode)))
               (not (memq buffer-mode
                          '(magit-process-mode
                            magit-revision-mode
                            magit-stash-mode
                            magit-status-mode))))
              '(display-buffer-same-window))
             ('(+magit--display-buffer-in-direction))))))

(defun +magit--display-buffer-in-direction (buffer alist)
  "`display-buffer-alist' handler that opens BUFFER in a direction."
  (let ((direction (or (alist-get 'direction alist)
                       +magit-open-windows-in-direction))
        (origin-window (selected-window)))
    (if-let* ((window (window-in-direction direction)))
        (unless magit-display-buffer-noselect
          (select-window window))
      (if-let* ((window (and (not (one-window-p))
                             (window-in-direction
                              (pcase direction
                                (`right 'left)
                                (`left 'right)
                                ((or `up `above) 'down)
                                ((or `down `below) 'up))))))
        (unless magit-display-buffer-noselect
          (select-window window))
        (let ((window (split-window nil nil direction)))
          (when (and (not magit-display-buffer-noselect)
                     (memq direction '(right down below)))
            (select-window window))
          (display-buffer-record-window 'reuse window buffer)
          (set-window-buffer window buffer)
          (set-window-parameter window 'quit-restore (list 'window 'window origin-window buffer))
          (set-window-prev-buffers window nil))))
    (unless magit-display-buffer-noselect
      (switch-to-buffer buffer t t)
      (selected-window))))

(defvar +magit--stale-p nil)

(defun +magit--revertable-buffer-p (buffer)
  (when (buffer-live-p buffer)
    (pcase +magit-auto-revert
      (`t t)
      (`local
       (not (file-remote-p
             (or (buffer-file-name buffer)
                 (buffer-local-value 'default-directory buffer)))))
      ((pred functionp)
       (funcall +magit-auto-revert buffer)))))

(defun +magit--revert-buffer (buffer)
  (with-current-buffer buffer
    (kill-local-variable '+magit--stale-p)
    (when (magit-auto-revert-repository-buffer-p buffer)
      (save-restriction
        (cl-incf magit-auto-revert-counter)
        (when (bound-and-true-p vc-mode)
          (let ((vc-follow-symlinks t))
            (vc-refresh-state))
          (when (fboundp '+vc-gutter-update-h)
            (+vc-gutter-update-h)))
        (when (and (not (get-buffer-process buffer))
                   (funcall buffer-stale-function t))
          (revert-buffer t t t))
        (force-mode-line-update)))))

(defun +magit-mark-stale-buffers-h ()
  "Revert all visible buffers and mark buried buffers as stale."
  (when +magit-auto-revert
    (let ((visible-buffers (doom-visible-buffers nil t)))
      (dolist (buffer (buffer-list))
        (when (+magit--revertable-buffer-p buffer)
          (if (memq buffer visible-buffers)
              (progn
                (+magit--revert-buffer buffer)
                (cl-callf2 delq buffer visible-buffers))
            (with-current-buffer buffer
              (setq-local +magit--stale-p t))))))))

(defun +magit-revert-buffer-maybe-h ()
  "Update `vc' and `diff-hl' if out of date."
  (when +magit--stale-p
    (+magit--revert-buffer (current-buffer))))

(defun +magit/quit (&optional kill-buffer)
  "Bury the current magit buffer.

If KILL-BUFFER, kill this buffer instead of burying it.  If the buried/killed
magit buffer was the last magit buffer open for this repo, kill all magit
buffers for this repo."
  (interactive "P")
  (let ((topdir (magit-toplevel)))
    (funcall magit-bury-buffer-function kill-buffer)
    (or (cl-find-if (lambda (win)
                      (with-selected-window win
                        (and (derived-mode-p 'magit-mode)
                             (equal magit--default-directory topdir))))
                    (window-list))
        (+magit/quit-all))))

(defun +magit/quit-all ()
  "Kill all magit buffers for the current repository."
  (interactive)
  (mapc #'+magit--kill-buffer (magit-mode-get-buffers))
  (+magit-mark-stale-buffers-h))

(defun +magit--kill-buffer (buf)
  "Kill BUF, waiting for its process to finish if it has one."
  (when (and (bufferp buf) (buffer-live-p buf))
    (let ((process (get-buffer-process buf)))
      (if (not (processp process))
          (kill-buffer buf)
        (with-current-buffer buf
          (if (process-live-p process)
              (run-with-timer 5 nil #'+magit--kill-buffer buf)
            (kill-process process)
            (kill-buffer buf)))))))

(defun +magit/start-code-review (arg)
  (interactive "P")
  (call-interactively
    (if (or arg (not (featurep 'forge)))
        #'code-review-start
      #'code-review-forge-pr-at-point)))

;;; tools/lsp.el ends here
