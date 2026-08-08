;;; app/rss.el --- doom app/rss port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/app/rss.
;;; Code:

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
    (when (or (null buf) (not (luna-real-buffer-p buf)))
      (switch-to-buffer (luna-fallback-buffer))))
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
  (setq elfeed-db-directory (luna-profile-data-dir t "elfeed" "db/")
        elfeed-enclosure-default-dir (luna-profile-data-dir t "elfeed" "enclosures/")
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

;;; app/rss.el ends here
