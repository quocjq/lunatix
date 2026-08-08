;;; ui/vc-gutter.el --- doom ui/vc-gutter port  -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/vc-gutter.
;;; no-byte-compile: byte/native-compiling this file hangs this laptop's native
;;; compiler; loaded from source instead (doom also loads configs interpreted).
;;; Code:

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
    (add-hook 'luna-load-theme-hook #'+vc-gutter-make-diff-hl-faces-transparent-h))

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
  :defer t
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
  ;;   refocusing the frame. APROX: doom's `luna-escape-hook'/`luna-switch-window-hook'
  ;;   are no-op in the compat layer; hook the real `window-buffer-change-functions'.
  (defvar-local +vc-gutter--last-state nil)
  (defun +vc-gutter-update-h (&rest _)
    "Return nil to prevent shadowing other `luna-escape-hook' hooks."
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

;;; ui/vc-gutter.el ends here
