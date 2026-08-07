;;; keybindings-config.el --- doom <leader> scheme, ported from
;;; doomemacs/modules/config/default/+evil-bindings.el  -*- lexical-binding: t; -*-

;; doom-only helpers, ported to vanilla equivalents.
(defun +doom/switch-to-scratch-buffer ()
  (interactive)
  (switch-to-buffer "*scratch*"))

(defun +doom/toggle-scratch-buffer ()
  (interactive)
  (if (equal (buffer-name) "*scratch*")
      (kill-buffer)
    (switch-to-buffer "*scratch*")))

(defun +doom/kill-all-buffers ()
  (interactive)
  (mapc #'kill-buffer
        (cl-remove-if #'buffer-modified-p
                      (buffer-list)))
  (switch-to-buffer "*scratch*"))

(defun +doom/kill-other-buffers ()
  (interactive)
  (mapc (lambda (buf)
          (unless (eq buf (current-buffer))
            (kill-buffer buf)))
        (buffer-list)))

(defun +doom/kill-buried-buffers ()
  (interactive)
  (mapc (lambda (buf)
          (when (and (not (eq buf (current-buffer)))
                     (eq (car (buffer-list)) buf))
            (kill-buffer buf)))
        (buffer-list)))

(defun +doom/yank-buffer-path ()
  (interactive)
  (when-let* ((path (buffer-file-name)))
    (kill-new path)
    (message "Copied %s" path)))

(defun +doom/delete-this-file ()
  (interactive)
  (when-let* ((path (buffer-file-name)))
    (when (yes-or-no-p (format "Delete %s?" path))
      (delete-file path)
      (kill-buffer))))

(defun +doom/copy-this-file ()
  (interactive)
  (when-let* ((path (buffer-file-name)))
    (let ((new (read-file-name "Copy to: ")))
      (copy-file path new)
      (message "Copied %s to %s" path new))))

(defun +doom/move-this-file ()
  (interactive)
  (when-let* ((path (buffer-file-name)))
    (let ((new (read-file-name "Move to: ")))
      (rename-file path new)
      (set-visited-file-name new t t)
      (message "Moved %s to %s" path new))))

(defun +doom/sudo-find-file (file)
  (interactive "Fsudo find file: ")
  (find-file (concat "/sudo:root@localhost:" file)))

(defun +doom/sudo-this-file ()
  (interactive)
  (when-let* ((path (buffer-file-name)))
    (find-alternate-file (concat "/sudo:root@localhost:" path))))

(defun +doom/insert-file-path ()
  (interactive)
  (when-let* ((path (buffer-file-name)))
    (insert path)))

(defun +doom/newline-below ()
  (interactive)
  (end-of-line)
  (newline-and-indent))

(defun +doom/newline-above ()
  (interactive)
  (beginning-of-line)
  (newline-and-indent)
  (forward-line -1)
  (indent-according-to-mode))

(defun +doom/backward-to-bol-or-indent ()
  (interactive)
  (if (or (bolp) (> (current-column) (current-indentation)))
      (back-to-indentation)
    (beginning-of-line)))

(defun +doom/forward-to-last-non-comment-or-eol ()
  (interactive)
  (if (eolp)
      (back-to-indentation)
    (end-of-line)))

(defun +doom/search-project-for-symbol-at-point ()
  (interactive)
  (let ((sym (thing-at-point 'symbol t)))
    (if sym
        (project-find-regexp (regexp-quote sym))
      (project-find-regexp))))

(defun +doom/previous-file ()
  "Cycle to the previous file (buffer + recentf list)."
  (interactive)
  (when-let* ((files (delete-dups
                      (delq nil (cons (buffer-file-name)
                                      (mapcar #'expand-file-name recentf-list)))))
              (cur (or (buffer-file-name) (car files)))
              (idx (cl-position cur files :test #'equal)))
    (find-file (nth (mod (1- idx) (length files)) files))))

(defun +doom/next-file ()
  "Cycle to the next file (buffer + recentf list)."
  (interactive)
  (when-let* ((files (delete-dups
                      (delq nil (cons (buffer-file-name)
                                      (mapcar #'expand-file-name recentf-list)))))
              (cur (or (buffer-file-name) (car files)))
              (idx (cl-position cur files :test #'equal)))
    (find-file (nth (mod (1+ idx) (length files)) files))))

;;; Leader tree

(lunatix-leader
  ;; top-level
  ";"   '(pp-eval-expression :wk "eval expression")
  ":"   '(execute-extended-command :wk "M-x")
  "x"   '(+doom/toggle-scratch-buffer :wk "toggle scratch")
  "X"   '(org-capture :wk "org capture")
  "u"   '(universal-argument :wk "universal argument")
  "w"   '(evil-window-map :wk "window")
  "h"   '(help-map :wk "help")
  "."   '(find-file :wk "find file")
  ","   '(switch-to-buffer :wk "switch buffer")
  "`"   '(evil-switch-to-windows-last-buffer :wk "last buffer")
  "'"   '(vertico-repeat :wk "resume search")
  "*"   '(+doom/search-project-for-symbol-at-point :wk "search symbol in project")
  "/"   '(project-find-regexp :wk "search project")
  "SPC" '(project-find-file :wk "find file in project")
  "RET" '(bookmark-jump :wk "jump to bookmark")

  ;; SPC b --- buffer
  "b"   '("buffer")
  "bb"  '(switch-to-buffer :wk "switch buffer")
  "bc"  '(clone-indirect-buffer :wk "clone buffer")
  "bC"  '(clone-indirect-buffer-other-window :wk "clone other window")
  "bd"  '(kill-current-buffer :wk "kill buffer")
  "bi"  '(ibuffer :wk "ibuffer")
  "bk"  '(kill-current-buffer :wk "kill buffer")
  "bK"  '(+doom/kill-all-buffers :wk "kill all buffers")
  "bl"  '(evil-switch-to-windows-last-buffer :wk "last buffer")
  "bm"  '(bookmark-set :wk "set bookmark")
  "bn"  '(next-buffer :wk "next buffer")
  "bN"  '(evil-buffer-new :wk "new buffer")
  "bO"  '(+doom/kill-other-buffers :wk "kill other buffers")
  "bp"  '(previous-buffer :wk "previous buffer")
  "br"  '(revert-buffer :wk "revert buffer")
  "bR"  '(rename-buffer :wk "rename buffer")
  "bs"  '(basic-save-buffer :wk "save buffer")
  "bS"  '(evil-write-all :wk "save all buffers")
  "bx"  '(+doom/toggle-scratch-buffer :wk "toggle scratch")
  "bX"  '(+doom/switch-to-scratch-buffer :wk "switch to scratch")
  "by"  '(+doom/yank-buffer-path :wk "yank buffer path")
  "bz"  '(bury-buffer :wk "bury buffer")
  "bZ"  '(+doom/kill-buried-buffers :wk "kill buried buffers")
  "b["  '(previous-buffer :wk "previous buffer")
  "b]"  '(next-buffer :wk "next buffer")

  ;; SPC c --- code
  "c"   '("code")
  "cc"  '(compile :wk "compile")
  "cC"  '(recompile :wk "recompile")
  "cd"  '(xref-find-definitions :wk "definition")
  "cD"  '(xref-find-references :wk "references")
  "ce"  '(eval-buffer :wk "eval buffer")
  "cE"  '(eval-defun :wk "eval defun")
  "cf"  '(apheleia-format-buffer :wk "format")
  "ci"  '(imenu :wk "imenu")
  "ck"  '(eldoc-doc-buffer :wk "documentation")
  "cl"  '(lsp :wk "lsp")
  "ca"  '(lsp-execute-code-action :wk "code action")
  "co"  '(lsp-organize-imports :wk "organize imports")
  "cr"  '(lsp-rename :wk "rename")
  "cw"  '(delete-trailing-whitespace :wk "delete trailing ws")
  "cx"  '(flycheck-list-errors :wk "list errors")

  ;; SPC f --- file
  "f"   '("file")
  "fc"  '(editorconfig-find-current-editorconfig :wk "find editorconfig")
  "fC"  '(+doom/copy-this-file :wk "copy this file")
  "fd"  '(dired-jump :wk "browse directory")
  "fD"  '(+doom/delete-this-file :wk "delete this file")
  "ff"  '(find-file :wk "find file")
  "fl"  '(locate :wk "locate file")
  "fr"  '(recentf-open-files :wk "recent files")
  "fR"  '(+doom/move-this-file :wk "rename/move file")
  "fs"  '(basic-save-buffer :wk "save file")
  "fS"  '(write-file :wk "save file as")
  "fu"  '(+doom/sudo-find-file :wk "sudo find file")
  "fU"  '(+doom/sudo-this-file :wk "sudo this file")
  "fy"  '(+doom/yank-buffer-path :wk "yank path")

  ;; SPC g --- git
  "g"   '("git")
  "g/"  '(magit-dispatch :wk "magit dispatch")
  "g."  '(magit-file-dispatch :wk "magit file dispatch")
  "gb"  '(magit-branch-checkout :wk "switch branch")
  "gB"  '(magit-blame-addition :wk "blame")
  "gC"  '(magit-clone :wk "clone")
  "gD"  '(magit-file-delete :wk "delete file")
  "gF"  '(magit-fetch :wk "fetch")
  "gg"  '(magit-status :wk "magit status")
  "gG"  '(magit-status-here :wk "magit status here")
  "gL"  '(magit-log-buffer-file :wk "buffer log")
  "gR"  '(vc-revert :wk "revert file")
  "gS"  '(magit-file-stage :wk "stage file")
  "gU"  '(magit-file-unstage :wk "unstage file")
  "gr"  '(diff-hl-revert-hunk :wk "revert hunk")
  "g["  '(diff-hl-previous-hunk :wk "previous hunk")
  "g]"  '(diff-hl-next-hunk :wk "next hunk")
  "gff" '(magit-find-file :wk "magit find file")
  "gfc" '(magit-show-commit :wk "find commit")
  "gfi" '(forge-visit-issue :wk "find issue")
  "gfp" '(forge-visit-pullreq :wk "find PR")
  "gcc" '(magit-commit-create :wk "commit")
  "gcr" '(magit-init :wk "init repo")
  "gcl" '(magit-log :wk "log")

  ;; SPC i --- insert
  "i"   '("insert")
  "if"  '(+doom/insert-file-path :wk "insert file path")
  "ir"  '(evil-show-registers :wk "registers")
  "is"  '(yas-insert-snippet :wk "snippet")
  "iu"  '(insert-char :wk "unicode")
  "iy"  '(yank-pop :wk "yank pop")

  ;; SPC n --- notes
  "n"   '("notes")
  "na"  '(org-agenda :wk "org agenda")
  "nd"  '(deft :wk "deft")
  "nl"  '(org-store-link :wk "store link")
  "nm"  '(org-tags-view :wk "tags search")
  "nn"  '(org-capture :wk "org capture")
  "nt"  '(org-todo-list :wk "todo list")

  ;; SPC o --- open
  "o"   '("open")
  "oA"  '(org-agenda :wk "org agenda")
  "ob"  '(browse-url-of-file :wk "browse file")
  "oe"  '(eshell :wk "eshell")
  "oE"  '(eshell :wk "eshell here")
  "of"  '(make-frame :wk "new frame")
  "oF"  '(select-frame-by-name :wk "select frame")
  "om"  '(wl :wk "wanderlust")
  "or"  '(ielm :wk "ielm")
  "ot"  '(vterm :wk "vterm")
  "oT"  '(vterm :wk "vterm here")
  "o-"  '(dired-jump :wk "dired")
  "oD"  '(docker :wk "docker")

  ;; SPC p --- project
  "p"   '("project")
  "p."  '(project-eshell :wk "eshell in project")
  "pb"  '(consult-project-buffer :wk "project buffers")
  "pf"  '(project-find-file :wk "find file in project")
  "pF"  '(project-find-dir :wk "find dir in project")
  "pp"  '(project-switch-project :wk "switch project")
  "pd"  '(project-find-dir :wk "project dir")
  "pD"  '(project-dired :wk "browse project")
  "pg"  '(project-find-regexp :wk "search project")
  "pr"  '(project-recentf :wk "recent project files")

  ;; SPC q --- quit
  "q"   '("quit")
  "qf"  '(delete-frame :wk "delete frame")
  "qK"  '(save-buffers-kill-emacs :wk "kill emacs")
  "qq"  '(save-buffers-kill-terminal :wk "quit emacs")
  "qQ"  '(evil-quit-all-with-error-code :wk "quit without saving")

  ;; SPC r --- remote
  "r"   '("remote")
  "ru"  '(ssh-deploy-upload-handler :wk "upload")
  "rU"  '(ssh-deploy-upload-handler-forced :wk "upload force")
  "rd"  '(ssh-deploy-download-handler :wk "download")
  "rb"  '(ssh-deploy-browse-remote-base-handler :wk "browse remote")
  "rB"  '(ssh-deploy-browse-remote-handler :wk "browse relative")
  "ro"  '(ssh-deploy-open-remote-file-handler :wk "open remote")
  "rs"  '(ssh-deploy-run-deploy-script-handler :wk "deploy script")
  "rx"  '(ssh-deploy-diff-handler :wk "diff remote")

  ;; SPC s --- search
  "s"   '("search")
  "sb"  '(consult-line :wk "search buffer")
  "sB"  '(consult-line-multi :wk "search all buffers")
  "sd"  '(consult-ripgrep :wk "search directory")
  "sf"  '(locate :wk "locate file")
  "si"  '(imenu :wk "jump to symbol")
  "sI"  '(consult-imenu-multi :wk "symbol in buffers")
  "sl"  '(link-hint-open-link :wk "visible link")
  "sj"  '(evil-show-jumps :wk "jump list")
  "sm"  '(bookmark-jump :wk "bookmark")
  "sp"  '(project-find-regexp :wk "search project")
  "sr"  '(evil-show-marks :wk "jump to mark")
  "ss"  '(consult-line :wk "search buffer")

  ;; SPC t --- toggle
  "t"   '("toggle")
  "td"  '(diff-hl-mode :wk "diff highlights")
  "tf"  '(flycheck-mode :wk "flycheck")
  "tF"  '(toggle-frame-fullscreen :wk "fullscreen")
  "tg"  '(evil-goggles-mode :wk "evil goggles")
  "ti"  '(indent-bars-mode :wk "indent guides")
  "tl"  '(display-line-numbers-mode :wk "line numbers")
  "tr"  '(read-only-mode :wk "read-only")
  "tw"  '(visual-line-mode :wk "soft wrap")

  ;; SPC T --- tabs/workspaces
  "T"   '("workspace")
  "T."  '(persp-switch :wk "switch workspace")
  "T`"  '(persp-switch-last :wk "last workspace")
  "Tn"  '(persp-switch :wk "new workspace")
  "Tl"  '(persp-state-load :wk "load workspace")
  "Ts"  '(persp-state-save :wk "save workspace")
  "Tr"  '(persp-rename :wk "rename workspace")
  "Td"  '(persp-kill :wk "kill workspace")
  "T["  '(persp-prev :wk "previous workspace")
  "T]"  '(persp-next :wk "next workspace"))

;; Major-mode localleader prefix (SPC m). Mode maps exist only once the mode
;; loads, so attach per-mode through hooks.
(general-create-definer lunatix-localleader
  :states '(normal visual emacs)
  :prefix "SPC m"
  :keymaps 'local)

(defun +doom/org-localleader ()
  (lunatix-localleader
    "a"   '(org-agenda :wk "agenda")
    "l"   '(org-store-link :wk "store link")
    "n"   '(org-capture :wk "capture")
    "t"   '(org-todo-list :wk "todo")
    "T"   '(org-todo :wk "set todo")
    "-"   '(org-insert-structure-template :wk "template")
    "d"   '(org-deadline :wk "deadline")
    "s"   '(org-schedule :wk "schedule")
    "e"   '(org-export-dispatch :wk "export")))

(defun +doom/elisp-localleader ()
  (lunatix-localleader
    "e"   '(eval-buffer :wk "eval buffer")
    "d"   '(eval-defun :wk "eval defun")
    "r"   '(eval-region :wk "eval region")))

(defun +doom/python-localleader ()
  (lunatix-localleader
    "e"   '(python-shell-send-buffer :wk "send buffer")
    "r"   '(python-shell-send-region :wk "send region")
    "f"   '(python-shell-send-defun :wk "send defun")))

(add-hook 'org-mode-hook #'+doom/org-localleader)
(add-hook 'emacs-lisp-mode-hook #'+doom/elisp-localleader)
(add-hook 'lisp-interaction-mode-hook #'+doom/elisp-localleader)
(add-hook 'python-mode-hook #'+doom/python-localleader)

;; doom-ish global fixes
(general-define-key
  :keymaps 'override
  "M-x" #'execute-extended-command
  "A-x" #'execute-extended-command)

;; Smarter readline-ish C-a/C-e in insert state
(general-define-key
  :states 'insert
  "C-a" #'+doom/backward-to-bol-or-indent
  "C-e" #'+doom/forward-to-last-non-comment-or-eol
  "C-RET" #'+doom/newline-below
  "C-S-RET" #'+doom/newline-above)

;; consult-history in minibuffer (doom convention)
(with-eval-after-load 'consult
  (dolist (map (list minibuffer-local-map
                     minibuffer-local-ns-map
                     minibuffer-local-completion-map
                     minibuffer-local-must-match-map
                     minibuffer-local-isearch-map))
    (define-key map (kbd "C-s") #'consult-history)))

;; one ESC press aborts the minibuffer (doom convention)
(dolist (map (list minibuffer-local-map
                   minibuffer-local-ns-map
                   minibuffer-local-completion-map
                   minibuffer-local-must-match-map
                   minibuffer-local-isearch-map
                   read-expression-map))
  (define-key map [escape] #'abort-recursive-edit))
(with-eval-after-load 'evil
  (when (boundp 'evil-ex-completion-map)
    (define-key evil-ex-completion-map [escape] #'abort-recursive-edit))
  (when (boundp 'evil-ex-search-keymap)
    (define-key evil-ex-search-keymap [escape] #'abort-recursive-edit)))

;;; Bracket navigation (doom `[`/`]` prefixes) — prev/next across things
(general-def :states '(normal visual)
  :prefix "["
  "b" #'previous-buffer
  "B" #'previous-buffer-other-window
  "f" #'+doom/previous-file
  "d" #'previous-error
  "D" #'flycheck-previous-error
  "h" #'diff-hl-previous-hunk
  "s" #'evil-search-previous
  "w" #'previous-multiframe-window)
(general-def :states '(normal visual)
  :prefix "]"
  "b" #'next-buffer
  "B" #'next-buffer-other-window
  "f" #'+doom/next-file
  "d" #'next-error
  "D" #'flycheck-next-error
  "h" #'diff-hl-next-hunk
  "s" #'evil-search-next
  "w" #'next-multiframe-window)

;;; keybindings-config.el ends here
(provide 'keybindings-config)
