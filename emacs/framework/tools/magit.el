;;; tools/magit.el --- doom tools/magit port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/tools/magit. Uses the lunatix-doom compat layer.
;;; Code:

(leaf magit
  :ensure t
  :commands magit-file-delete
  :bind ("C-x g" . magit-status)
  :init
  (setq magit-auto-revert-mode nil)  ; we do this ourselves further down
  :config
  (setq magit-diff-refine-hunk t
        magit-save-repository-buffers nil
        magit-revision-insert-related-refs nil
        ;; Use the full path as the project name to prevent name collisions
        ;; between same-named projects.
        magit-uniquify-buffer-names nil
        magit-git-executable (or (executable-find magit-git-executable) "git"))

  ;; Turn ref links into clickable buttons.
  (add-hook 'magit-process-mode-hook #'goto-address-mode)

  ;; Since the project likely now contains new files, purge the projectile
  ;; cache so `projectile-find-file' et all don't produce an stale file list.
  (defvar +magit--last-hash nil)
  (defun +magit-invalidate-projectile-cache-h ()
    (when (bound-and-true-p projectile-mode)
      (let ((hash (buffer-hash))
            projectile-require-project-root
            projectile-enable-caching
            projectile-verbose)
        (unless (equal +magit--last-hash hash)
          (letf! ((#'recentf-cleanup #'ignore))
            (projectile-invalidate-cache nil))
          (setq-local +magit--last-hash hash)))))
  (add-hook 'magit-refresh-buffer-hook #'+magit-invalidate-projectile-cache-h)

  ;; Use a more efficient strategy to auto-revert buffers whose git state has
  ;; changed.
  (add-hook 'magit-post-refresh-hook #'+magit-mark-stale-buffers-h)
  (add-hook 'luna-switch-buffer-hook #'+magit-revert-buffer-maybe-h)
  (add-hook 'doom-switch-frame-hook #'+magit-mark-stale-buffers-h)

  ;; Prevent sudden window position resets when staging/unstaging hunks.
  (defvar +magit--refreshed-buffer nil)
  (defun +magit--set-window-state-h ()
    (when (luna-region-active-p)
      (setq-local +magit--refreshed-buffer
                  (list (current-buffer) (doom-region-beginning) (window-start)))))
  (add-hook 'magit-pre-refresh-hook #'+magit--set-window-state-h)
  (defun +magit--restore-window-state-h ()
    (cl-destructuring-bind (&optional buf pt beg) +magit--refreshed-buffer
      (when (and buf (eq (current-buffer) buf))
        (goto-char pt)
        (set-window-start nil beg t)
        (kill-local-variable '+magit--refreshed-buffer))))
  (add-hook 'magit-post-refresh-hook #'+magit--restore-window-state-h)

  (setq magit-display-buffer-function #'+magit-display-buffer-fn
        magit-bury-buffer-function #'magit-mode-quit-window)

  ;; The mode-line isn't useful in these popups.
  (when (fboundp 'mode-line-invisible-mode)
    (add-hook 'magit-popup-mode-hook #'mode-line-invisible-mode))

  ;; Line numbers add nothing to magit's buffers.
  (add-hook 'magit-popup-mode-hook #'luna-disable-line-numbers-h)
  (add-hook 'magit-mode-hook #'luna-disable-line-numbers-h)

  ;; Add additional switches that seem common enough.
  (transient-append-suffix 'magit-fetch "-p"
    '("-t" "Fetch all tags" ("-t" "--tags")))
  (transient-append-suffix 'magit-pull "-r"
    '("-a" "Autostash" "--autostash"))

  ;; So magit buffers can be switched to (except for process buffers).
  (defun +magit-buffer-p (buf)
    (let ((mode (buffer-local-value 'major-mode buf)))
      (and (provided-mode-derived-p mode 'magit-mode)
           (not (eq mode 'magit-process-mode)))))
  (add-hook 'luna-real-buffer-functions #'+magit-buffer-p)

  ;; Clean up after magit by killing leftover magit buffers.
  (define-key magit-mode-map "q" #'+magit/quit)
  (define-key magit-mode-map "Q" #'+magit/quit-all)

  (defun +magit-enlargen-fringe-h ()
    "Make fringe larger in magit."
    (and (display-graphic-p)
         (derived-mode-p 'magit-section-mode)
         +magit-fringe-size
         (let ((left  (or (car-safe +magit-fringe-size) +magit-fringe-size))
               (right (or (cdr-safe +magit-fringe-size) +magit-fringe-size)))
           (unless (and (= left  (or left-fringe-width 0))
                        (= right (or right-fringe-width 0)))
             (set-window-fringes nil left right)))))
  (add-hook 'magit-section-mode-hook
            (lambda ()
              (add-hook 'window-configuration-change-hook #'+magit-enlargen-fringe-h nil t)))

  (defun +magit-reveal-point-if-invisible-h ()
    "Reveal the point if in an invisible region."
    (if (derived-mode-p 'org-mode)
        (org-reveal '(4))
      (require 'reveal)
      (reveal-post-command)))
  (add-hook 'magit-diff-visit-file-hook #'+magit-reveal-point-if-invisible-h)

  ;; HACK: See magit/magit#5320: large/long status buffers can change the
  ;;   behavior of motions and TAB in obscure ways.
  (add-hook 'magit-status-mode-hook (lambda () (setq-local long-line-threshold nil))))

(leaf forge
  :ensure t
  :when (modulep! :tools magit +forge)
  :after magit
  :commands forge-create-pullreq forge-create-issue
  :preface
  (setq forge-database-file (luna-profile-data-dir t "forge" "forge-database.sqlite"))
  (setq forge-add-default-bindings (not (modulep! :editor evil +everywhere)))
  :init
  (after! ghub-graphql
    (setq ghub-graphql-message-progress t))
  :config
  (evil-define-key 'normal forge-topic-list-mode-map "q" #'kill-current-buffer)
  (when (not forge-add-default-bindings)
    (define-key magit-mode-map [remap magit-browse-thing] #'forge-browse)
    (define-key magit-remote-section-map [remap magit-browse-thing] #'forge-browse-remote)
     (define-key magit-branch-section-map [remap magit-browse-thing] #'forge-browse-branch)))

;; code-review dropped: its use-package compile-time load breaks on the
;; emacsql↔forge class mismatch in nixpkgs; +magit/start-code-review kept
;; defined but inert until code-review is loadable.

;; evil-collection handles magit bindings itself; the extra
;; evil-collection-magit/-magit-section leafs are dropped (their files no
;; longer ship standalone in this evil-collection version).

(leaf git-commit
  :ensure t
  :defer t
  :init
  ;; Enforce git commit conventions.
  ;; See https://chris.beams.io/posts/git-commit/
  (setq git-commit-summary-max-length 50
        git-commit-style-convention-checks '(overlong-summary-line non-empty-second-line))
  :config
  (global-git-commit-mode 1)
  (add-hook 'git-commit-mode-hook #'yas-minor-mode)
  (add-hook 'git-commit-mode-hook (lambda () (setq-local fill-column 72)))

  (defun +vc-start-in-insert-state-maybe-h ()
    "Start git-commit-mode in insert state if in a blank commit message."
    (when (and (bound-and-true-p evil-local-mode)
               (not (evil-emacs-state-p))
               (bobp) (eolp))
      (evil-insert-state)))
  (add-hook 'git-commit-setup-hook #'+vc-start-in-insert-state-maybe-h))

;;
;;; tools/pass

(defvar +pass-user-fields '("login" "user" "username" "email")
  "A list of fields for `+pass/ivy' to search for the username.")

(defvar +pass-url-fields '("url" "site" "location")
  "A list of fields for `+pass/ivy' to search for the username.")

(setq password-store-password-length 12)

(defun +pass--copy-username (entry)
  (if-let* ((user (+pass-get-field entry +pass-user-fields)))
      (progn (password-store-clear)
             (message "Copied username to the kill ring.")
             (kill-new user))
    (error "Username not found.")))

(defalias '+pass-get-entry #'auth-source-pass-parse-entry)

(defun +pass-get-field (entry fields &optional noerror)
  "Fetches the value of a field.  FIELDS can be a list of string field names or
a single one.  If a list, the first field found will be returned."
  (if-let* ((data (if (listp entry) entry (+pass-get-entry entry))))
      (cl-loop for key in (ensure-list fields)
               when (assoc key data)
               return (cdr it))
    (unless noerror
      (error "Couldn't find entry: %s" entry))))

(defun +pass-get-user (entry)
  "Fetches the user field from ENTRY."
  (+pass-get-field entry +pass-user-fields))

(defun +pass-get-secret (entry)
  "Fetches your secret from ENTRY."
  (+pass-get-field entry 'secret))

(define-obsolete-function-alias '+pass/edit-entry #'password-store-edit "21.12")
(define-obsolete-function-alias '+pass/copy-field #'password-store-copy-field "21.12")
(define-obsolete-function-alias '+pass/copy-secret #'password-store-copy "21.12")
(define-obsolete-function-alias '+pass/browse-url #'password-store-url "21.12")

(defun +pass/copy-user (entry)
  "Interactively search for an entry and copy the login to your clipboard."
  (interactive
   (list (password-store--completing-read)))
  (+pass--copy-username entry))

(defun +pass/consult (arg pass)
  "Complete and act on password store entries with consult."
  (interactive
   (list current-prefix-arg
         (progn
           (require 'consult)
           (consult--read (password-store-list)
                          :prompt "Pass: "
                          :sort nil
                          :require-match t
                          :category 'pass))))
  (funcall (if arg
               #'password-store-url
             #'password-store-copy)
           pass))

;;; tools/magit.el ends here
