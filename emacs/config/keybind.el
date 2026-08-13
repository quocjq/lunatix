;;; keybind.el --- the single home for every keybinding  -*- lexical-binding: t; -*-
;;;
;;; RULE: ALL keybindings — `define-key', `map!', `lbind', `general-define-key',
;;; `evil-define-key', `[remap ...]', `global-set-key', localleader/mode maps —
;;; MUST be declared here, grouped by package under `(after! <pkg> ...)'.
;;; Source files never bind keys; they may only define the commands they bind.
;;; Defer every mode-map bind with `after!' so the keymap exists when it runs.

;; Buffer/path/file helpers live in lunaris.el (luna/* prefix).

;;; Leader tree

(lunatix-leader
  ;; top-level
  ";"   '(pp-eval-expression :wk "eval expression")
  ":"   '(execute-extended-command :wk "M-x")
  "x"   '(luna/toggle-scratch-buffer :wk "toggle scratch")
  "X"   '(org-capture :wk "org capture")
  "u"   '(vundo :wk "undo tree")
  "w"   '(evil-window-map :wk "window")
  "h"   '(help-map :wk "help")
  "."   '(find-file :wk "find file")
  ","   '(switch-to-buffer :wk "switch buffer")
  "`"   '(evil-switch-to-windows-last-buffer :wk "last buffer")
  "'"   '(vertico-repeat :wk "resume search")
  "*"   '(luna/search-project-for-symbol-at-point :wk "search symbol in project")
  "/"   '(projectile-ripgrep :wk "search project")
  "SPC" '(projectile-find-file :wk "find file in project")
  "RET" '(bookmark-jump :wk "jump to bookmark")

  ;; SPC b --- buffer
  "b"   '("buffer")
  "bb"  '(switch-to-buffer :wk "switch buffer")
  "bc"  '(clone-indirect-buffer :wk "clone buffer")
  "bC"  '(clone-indirect-buffer-other-window :wk "clone other window")
  "bd"  '(kill-current-buffer :wk "kill buffer")
  "bi"  '(ibuffer :wk "ibuffer")
  "bk"  '(kill-current-buffer :wk "kill buffer")
  "bK"  '(luna/kill-all-buffers :wk "kill all buffers")
  "bl"  '(evil-switch-to-windows-last-buffer :wk "last buffer")
  "bm"  '(bookmark-set :wk "set bookmark")
  "bn"  '(next-buffer :wk "next buffer")
  "bN"  '(evil-buffer-new :wk "new buffer")
  "bO"  '(luna/kill-other-buffers :wk "kill other buffers")
  "bp"  '(previous-buffer :wk "previous buffer")
  "br"  '(revert-buffer :wk "revert buffer")
  "bR"  '(rename-buffer :wk "rename buffer")
  "bs"  '(basic-save-buffer :wk "save buffer")
  "bS"  '(evil-write-all :wk "save all buffers")
  "bx"  '(luna/toggle-scratch-buffer :wk "toggle scratch")
  "bX"  '(luna/switch-to-scratch-buffer :wk "switch to scratch")
  "by"  '(luna/yank-buffer-path :wk "yank buffer path")
  "bz"  '(bury-buffer :wk "bury buffer")
  "bZ"  '(luna/kill-buried-buffers :wk "kill buried buffers")
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
  "fC"  '(luna/copy-this-file :wk "copy this file")
  "fd"  '(dired-jump :wk "browse directory")
  "fD"  '(luna/delete-this-file :wk "delete this file")
  "ff"  '(find-file :wk "find file")
  "fl"  '(locate :wk "locate file")
  "fr"  '(recentf-open-files :wk "recent files")
  "fR"  '(luna/move-this-file :wk "rename/move file")
  "fs"  '(basic-save-buffer :wk "save file")
  "fS"  '(write-file :wk "save file as")
  "fu"  '(luna/sudo-find-file :wk "sudo find file")
  "fU"  '(luna/sudo-this-file :wk "sudo this file")
  "fy"  '(luna/yank-buffer-path :wk "yank path")

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
  "gcM" '(magit-commit-create :wk "commit")
  "gcr" '(magit-init :wk "init repo")
  "gcl" '(magit-log :wk "log")

  ;; SPC i --- insert
  "i"   '("insert")
  "if"  '(luna/insert-file-path :wk "insert file path")
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
  "od"  '(+dashboard/open :wk "open dashboard")
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
  "on"  '(lwf-note :wk "note workflow")
  "ow"  '(lwf-open :wk "open workflow")
  "o-"  '(dired-jump :wk "dired")
  "oD"  '(docker :wk "docker")
  "ol"  '("lnav")
  "olj" '(lnav-jump-before-open :wk "before open")
  "ola" '(lnav-jump-after-open :wk "after open")
  "olc" '(lnav-jump-before-close :wk "before close")
  "old" '(lnav-jump-after-close :wk "after close")
  "oln" '(lnav-next-chunk :wk "next chunk")
  "olp" '(lnav-previous-chunk :wk "prev chunk")
  "oli" '(lnav-chunk-in :wk "chunk in")
  "olo" '(lnav-chunk-out :wk "chunk out")
  "ols" '(lnav-select-chunk :wk "select chunk")
  "olS" '(lnav-select-chunk-around :wk "select chunk around")
  "olw" '(lnav-surround :wk "surround")
  "olx" '(lnav-delete-enclosing-pair :wk "delete pair")
  "olr" '(lnav-change-enclosing-pair :wk "change pair")
  "ol>" '(lnav-slurp-forward :wk "slurp forward")
  "ol<" '(lnav-slurp-backward :wk "slurp backward")
  "ol]" '(lnav-barf-forward :wk "barf forward")
  "ol[" '(lnav-barf-backward :wk "barf backward")
  "olk" '(lnav-kill-sexp :wk "kill sexp")
  "olt" '(lnav-transpose-sexp :wk "transpose")
  "olR" '(lnav-raise-sexp :wk "raise")
  "olf" '(lnav-forward-sexp :wk "forward sexp")
  "olF" '(lnav-backward-sexp :wk "backward sexp")
  "olz" '(lnav-flash-chunk :wk "flash chunks")
  "olZ" '(lnav-flash-char :wk "flash char")
  "ol/" '(lnav-flash-search :wk "flash search")

  ;; SPC p --- project
  "p"   '("project")
  "p!"  '(projectile-run-shell-command-in-root :wk "shell in project")
  "pb"  '(projectile-switch-to-buffer :wk "project buffers")
  "pc"  '(projectile-compile-project :wk "compile project")
  "pf"  '(projectile-find-file :wk "find file in project")
  "pF"  '(projectile-find-dir :wk "find dir in project")
  "pi"  '(projectile-invalidate-cache :wk "invalidate cache")
  "pp"  '(projectile-switch-project :wk "switch project")
  "pd"  '(projectile-dired :wk "browse project")
  "pr"  '(projectile-recentf :wk "recent project files")
  "pR"  '(projectile-run-project :wk "run project")
  "pT"  '(projectile-test-project :wk "test project")
  "pt"  '(luna/tmux-project-session :wk "tmux session (project)")
  "ps"  '(luna/tmux-sessionizer :wk "tmux sessionizer")

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
  "sp"  '(projectile-ripgrep :wk "search project")
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

  ;; SPC TAB --- workspace manager (doom :ui workspaces). Flat keys: the
  ;; leader definer can't nest a sub-prefix via :prefix (it overrides SPC).
  "TAB"    '("workspace")
  "TAB TAB" '(+workspace/display :wk "display tab bar")
  "TAB ." '(+workspace/switch-to :wk "switch workspace")
  "TAB `" '(+workspace/other :wk "last workspace")
  "TAB n" '(+workspace/new :wk "new workspace")
  "TAB N" '(+workspace/new-named :wk "new named workspace")
  "TAB l" '(+workspace/load :wk "load workspace")
  "TAB s" '(+workspace/save :wk "save workspace")
  "TAB x" '(+workspace/kill-session :wk "kill session")
  "TAB d" '(+workspace/kill :wk "kill workspace")
  "TAB D" '(+workspace/delete :wk "delete workspace")
  "TAB r" '(+workspace/rename :wk "rename workspace")
  "TAB R" '(+workspace/restore-last-session :wk "restore session")
  "TAB [" '(+workspace/switch-left :wk "previous workspace")
  "TAB ]" '(+workspace/switch-right :wk "next workspace")
  "TAB 1" '(+workspace/switch-to-0 :wk "workspace 1")
  "TAB 2" '(+workspace/switch-to-1 :wk "workspace 2")
  "TAB 3" '(+workspace/switch-to-2 :wk "workspace 3")
  "TAB 4" '(+workspace/switch-to-3 :wk "workspace 4")
  "TAB 5" '(+workspace/switch-to-4 :wk "workspace 5")
  "TAB 6" '(+workspace/switch-to-5 :wk "workspace 6")
  "TAB 7" '(+workspace/switch-to-6 :wk "workspace 7")
  "TAB 8" '(+workspace/switch-to-7 :wk "workspace 8")
  "TAB 9" '(+workspace/switch-to-8 :wk "workspace 9")
  "TAB 0" '(+workspace/switch-to-final :wk "final workspace"))

;; workspace global keys (doom)
(general-define-key
  :states 'normal
  "C-t"   #'+workspace/new
  "C-S-t" #'+workspace/display)
(dotimes (i 9)
  (general-define-key
    :states 'normal
    (kbd (format "M-%d" (1+ i)))
    (intern (format "+workspace/switch-to-%d" i))))
(general-define-key
  :states 'normal
  (kbd "M-0") #'+workspace/switch-to-final)


;; Major-mode localleader prefix (SPC m). Mode maps exist only once the mode
;; loads, so attach per-mode through hooks.
(general-create-definer lunatix-localleader
  :states '(normal visual motion)
  :prefix "SPC m"
  :keymaps 'local)

(add-hook 'org-mode-hook #'luna/org-localleader)
(add-hook 'emacs-lisp-mode-hook #'luna/elisp-localleader)
(add-hook 'lisp-interaction-mode-hook #'luna/elisp-localleader)
(add-hook 'python-mode-hook #'luna/python-localleader)

;; doom-ish global fixes
(general-define-key
  :keymaps 'override
  "M-x" #'execute-extended-command
  "A-x" #'execute-extended-command)

;; Smarter readline-ish C-a/C-e in insert state
(general-define-key
  :states 'insert
  "C-a" #'luna/backward-to-bol-or-indent
  "C-e" #'luna/forward-to-last-non-comment-or-eol
  "C-RET" #'luna/newline-below
  "C-S-RET" #'luna/newline-above)

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
  "f" #'luna/previous-file
  "d" #'previous-error
  "D" #'flycheck-previous-error
  "h" #'diff-hl-previous-hunk
  "s" #'evil-search-previous
  "w" #'previous-multiframe-window)
(general-def :states '(normal visual)
  :prefix "]"
  "b" #'next-buffer
  "B" #'next-buffer-other-window
  "f" #'luna/next-file
  "d" #'next-error
  "D" #'flycheck-next-error
  "h" #'diff-hl-next-hunk
  "s" #'evil-search-next
  "w" #'next-multiframe-window)

;; font zoom (doom)
(general-define-key
  :states '(normal)
  "C-="   #'text-scale-increase
  "C--"   #'text-scale-decrease
  "C-+"   #'luna/reset-font-size
  "M-C-=" #'luna/increase-font-size
  "M-C--" #'luna/decrease-font-size)

;; =====================================================================
;; Unified global + mode keybindings — the single home for every key.
;; =====================================================================
;; Global / evil-state
(general-define-key :states '(normal visual) "q" #'delete-window)
(global-set-key [remap other-window] #'ace-window)
(global-set-key (kbd "C-.") #'embark-act)
(global-set-key [remap eval-region] #'+eval/region)
(global-set-key [remap eval-buffer] #'+eval/buffer)
(global-set-key [remap xref-find-definitions] #'+lookup/definition)
(global-set-key [remap xref-find-references]  #'+lookup/references)

;; emacs-state: ESC/C-g back to normal; backspace deletes, never joins lines
(after! evil
  (define-key evil-emacs-state-map (kbd "<escape>") 'evil-normal-state)
  (define-key evil-emacs-state-map (kbd "C-g") 'evil-normal-state)
  (define-key evil-emacs-state-map (kbd "DEL") #'delete-backward-char)
  (define-key evil-emacs-state-map (kbd "C-h") #'delete-backward-char))

;; Package commands (previously leaf `:bind')
(general-def "C-c d"   #'deft)
(general-def "C-'"    #'popper-toggle)
(general-def "M-`"    #'popper-cycle)
(general-def "C-x g"  #'magit-status)
(general-def "M-g j"  #'dumb-jump-go)

;; Mode maps (bound once the mode loads)
(after! dired
  (define-key dired-mode-map (kbd "C-c C-e") #'wdired-change-to-wdired-mode)
  (general-define-key :keymaps 'dired-mode-map :states '(normal visual)
    "h" #'dired-up-directory
    "l" #'dired-find-file))
(after! dirvish
  (define-key dired-mode-map (kbd "C-c C-r") #'dirvish-rsync)
  (general-define-key :keymaps 'dired-mode-map :states '(normal visual)
    "h" #'dired-up-directory
    "l" #'dired-find-file))
(after! apheleia
  (when (boundp 'apheleia-mode-map)
    (define-key apheleia-mode-map [remap basic-save-buffer] #'+format/save-buffer)))
(after! vertico
  (general-define-key :keymaps 'vertico-map
    "M-RET" #'vertico-exit-input
    "C-j"   #'vertico-next
    "C-k"   #'vertico-previous
    "C-h"   (lambda () (interactive)
              (when (eq 'file (vertico--metadata-get 'category))
                (vertico-directory-up)))
    "C-l"   #'+vertico/enter-or-preview
    "DEL"   #'vertico-directory-delete-char))
(after! lsp-ui-peek
  (define-key lsp-ui-peek-mode-map "j"   #'lsp-ui-peek--select-next)
  (define-key lsp-ui-peek-mode-map "k"   #'lsp-ui-peek--select-prev)
  (define-key lsp-ui-peek-mode-map (kbd "C-k") #'lsp-ui-peek--select-prev-file)
  (define-key lsp-ui-peek-mode-map (kbd "C-j") #'lsp-ui-peek--select-next-file))
(after! magit
  (define-key magit-mode-map "q" #'+magit/quit)
  (define-key magit-mode-map "Q" #'+magit/quit-all))
(after! deft
  (map! :map deft-mode-map
        :n "gr"  #'deft-refresh
        :n "C-s" #'deft-filter
        :i "C-n" #'deft-new-file
        :i "C-m" #'deft-new-file-named
        :i "C-d" #'deft-delete-file
        :i "C-r" #'deft-rename-file
        :n "r"   #'deft-rename-file
        :n "a"   #'deft-new-file
        :n "A"   #'deft-new-file-named
        :n "d"   #'deft-delete-file
        :n "D"   #'deft-archive-file
        :n "q"   #'kill-current-buffer)
  (condition-case nil
      (general-def :keymaps 'deft-mode-map :prefix luna-localleader-key
        "RET" #'deft-new-file-named
        "a"   #'deft-archive-file
        "c"   #'deft-filter-clear
        "d"   #'deft-delete-file
        "f"   #'deft-find-file
        "g"   #'deft-refresh
        "l"   #'deft-filter
        "n"   #'deft-new-file
        "r"   #'deft-rename-file
        "s"   #'deft-toggle-sort-method
        "t"   #'deft-toggle-incremental-search)
    (error nil)))

;; =====================================================================
;; Framework/mode bindings — every key, grouped by package.  Migrated
;; here from the framework modules (RULE: keys live only in this file).
;; =====================================================================

;; --- org (framework/lang/org.el) -------------------------------------
(after! org
  (define-key org-src-mode-map (kbd "C-c C-c") #'org-edit-src-exit)
  (general-define-key
   :keymaps 'org-mode-map
   "C-c C-S-l"  #'+org/remove-link
   "C-c <C-i>"  #'org-link-preview-refresh
   "S-RET"      #'+org/shift-return
   "C-RET"      #'+org/insert-item-below
   "C-S-RET"    #'+org/insert-item-above
   "C-M-RET"    #'org-insert-subheading
   [C-return]   #'+org/insert-item-below
   [C-S-return] #'+org/insert-item-above
   [C-M-return] #'org-insert-subheading
   [remap luna/backward-to-bol-or-indent]          #'org-beginning-of-line
   [remap luna/forward-to-last-non-comment-or-eol] #'org-end-of-line)
  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual motion)
   :prefix luna-localleader-key
   "#" '(org-update-statistics-cookies :wk "update statistics cookies")
   "'" '(org-edit-special :wk "edit source")
   "*" '(org-ctrl-c-star :wk "toggle section")
   "-" '(org-ctrl-c-minus :wk "toggle item")
   "," '(org-switchb :wk "switch buffer")
   "." '(consult-org-heading :wk "jump to heading")
   "/" '(consult-org-agenda :wk "jump to heading in agenda files")
   "@" '(org-cite-insert :wk "insert citation")
   "A" '(org-archive-subtree-default :wk "archive subtree")
   "e" '(org-export-dispatch :wk "export")
   "f" '(org-footnote-action :wk "footnote")
   "h" '(org-toggle-heading :wk "toggle heading")
   "i" '(org-toggle-item :wk "toggle item")
   "I" '(org-id-get-create :wk "create id")
   "k" '(org-babel-remove-result :wk "remove babel result")
   "K" '(#'+org/remove-result-blocks :wk "remove result blocks")
   "n" '(org-store-link :wk "store link")
   "o" '(org-set-property :wk "set property")
   "q" '(org-set-tags-command :wk "set tags")
   "t" '(org-todo :wk "todo")
   "T" '(org-todo-list :wk "todo list")
   "x" '(org-toggle-checkbox :wk "toggle checkbox"))
  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " a")
   "a" '(org-attach :wk "attach")
   "d" '(org-attach-delete-one :wk "delete one")
   "D" '(org-attach-delete-all :wk "delete all")
   "f" '(#'+org/find-file-in-attachments :wk "find file in attachments")
   "l" '(#'+org/attach-file-and-insert-link :wk "attach and insert link")
   "n" '(org-attach-new :wk "new attachment")
   "o" '(org-attach-open :wk "open")
   "O" '(org-attach-open-in-emacs :wk "open in emacs")
   "r" '(org-attach-reveal :wk "reveal")
   "R" '(org-attach-reveal-in-emacs :wk "reveal in emacs")
   "u" '(org-attach-url :wk "attach url")
   "s" '(org-attach-set-directory :wk "set directory")
   "S" '(org-attach-sync :wk "sync"))
  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " b")
   "-" '(org-table-insert-hline :wk "insert hline")
   "a" '(org-table-align :wk "align table")
   "b" '(org-table-blank-field :wk "blank field")
   "c" '(org-table-create-or-convert-from-region :wk "create table")
   "e" '(org-table-edit-field :wk "edit field")
   "f" '(org-table-edit-formulas :wk "edit formulas")
   "h" '(org-table-field-info :wk "field info")
   "s" '(org-table-sort-lines :wk "sort lines")
   "r" '(org-table-recalculate :wk "recalculate")
   "R" '(org-table-recalculate-buffer-tables :wk "recalculate buffer")
   "dc" '(org-table-delete-column :wk "delete column")
   "dr" '(org-table-kill-row :wk "kill row")
   "ic" '(org-table-insert-column :wk "insert column")
   "ih" '(org-table-insert-hline :wk "insert hline")
   "ir" '(org-table-insert-row :wk "insert row")
   "iH" '(org-table-hline-and-move :wk "insert hline and move")
   "tf" '(org-table-toggle-formula-debugger :wk "toggle formula debugger")
   "to" '(org-table-toggle-coordinate-overlays :wk "toggle coordinate overlays"))
  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " c")
   "c" '(org-clock-cancel :wk "cancel clock")
   "d" '(org-clock-mark-default-task :wk "mark default task")
   "e" '(org-clock-modify-effort-estimate :wk "modify effort")
   "E" '(org-set-effort :wk "set effort")
   "g" '(org-clock-goto :wk "goto clock")
   "G" '(cmd! (org-clock-goto 'select) :wk "goto clock (select)")
   "l" '(#'+org/toggle-last-clock :wk "toggle last clock")
   "i" '(org-clock-in :wk "clock in")
   "I" '(org-clock-in-last :wk "clock in last")
   "o" '(org-clock-out :wk "clock out")
   "r" '(org-resolve-clocks :wk "resolve clocks")
   "R" '(org-clock-report :wk "clock report")
   "t" '(org-evaluate-time-range :wk "evaluate time range")
   "=" '(org-clock-timestamps-up :wk "timestamps up")
   "-" '(org-clock-timestamps-down :wk "timestamps down"))
  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " d")
   "d" '(org-deadline :wk "deadline")
   "s" '(org-schedule :wk "schedule")
   "t" '(org-time-stamp :wk "time stamp")
   "T" '(org-time-stamp-inactive :wk "inactive time stamp"))
  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " g")
   "g" '(consult-org-heading :wk "jump to heading")
   "G" '(consult-org-agenda :wk "jump in agenda files")
   "c" '(org-clock-goto :wk "goto clock")
   "C" '(cmd! (org-clock-goto 'select) :wk "goto clock (select)")
   "i" '(org-id-goto :wk "goto id")
   "r" '(org-refile-goto-last-stored :wk "goto last refile")
   "v" '(#'+org/goto-visible :wk "goto visible heading")
   "x" '(org-capture-goto-last-stored :wk "goto last capture"))
  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " l")
   "c" '(org-cliplink :wk "cliplink")
   "d" '(#'+org/remove-link :wk "remove link")
   "i" '(org-id-store-link :wk "store id link")
   "l" '(org-insert-link :wk "insert link")
   "L" '(org-insert-all-links :wk "insert all links")
   "s" '(org-store-link :wk "store link")
   "S" '(org-insert-last-stored-link :wk "insert last stored link")
   "t" '(org-toggle-link-display :wk "toggle link display")
   "y" '(#'+org/yank-link :wk "yank link"))
  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " P")
   "a" '(org-publish-all :wk "publish all")
   "f" '(org-publish-current-file :wk "publish current file")
   "p" '(org-publish :wk "publish")
   "P" '(org-publish-current-project :wk "publish current project")
   "s" '(org-publish-sitemap :wk "publish sitemap"))
  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " r")
   "." '(#'+org/refile-to-current-file :wk "refile to current file")
   "c" '(#'+org/refile-to-running-clock :wk "refile to running clock")
   "l" '(#'+org/refile-to-last-location :wk "refile to last location")
   "f" '(#'+org/refile-to-file :wk "refile to file")
   "o" '(#'+org/refile-to-other-window :wk "refile to other window")
   "O" '(#'+org/refile-to-other-buffer :wk "refile to other buffer")
   "v" '(#'+org/refile-to-visible :wk "refile to visible")
   "r" '(org-refile :wk "refile")
   "R" '(org-refile-reverse :wk "refile reverse"))
  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " s")
   "a" '(org-toggle-archive-tag :wk "toggle archive tag")
   "b" '(org-tree-to-indirect-buffer :wk "tree to indirect buffer")
   "c" '(org-clone-subtree-with-time-shift :wk "clone subtree")
   "d" '(org-cut-subtree :wk "cut subtree")
   "h" '(org-promote-subtree :wk "promote subtree")
   "j" '(org-move-subtree-down :wk "move subtree down")
   "k" '(org-move-subtree-up :wk "move subtree up")
   "l" '(org-demote-subtree :wk "demote subtree")
   "n" '(org-narrow-to-subtree :wk "narrow to subtree")
   "r" '(org-refile :wk "refile")
   "s" '(org-sparse-tree :wk "sparse tree")
   "A" '(org-archive-subtree-default :wk "archive subtree")
   "N" '(widen :wk "widen")
   "S" '(org-sort :wk "sort"))
  (general-define-key
   :keymaps 'org-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " p")
   "d" '(org-priority-down :wk "priority down")
   "p" '(org-priority :wk "priority")
   "u" '(org-priority-up :wk "priority up")))
(after! org-agenda
 (general-define-key
  :keymaps 'org-agenda-mode-map
  :states '(motion normal)
  "C-SPC" #'org-agenda-show-and-scroll-up)
 ;; org-agenda-mode-map (and its evil state maps, via evil-collection) binds
 ;; SPC to scroll (org-agenda.el), which blocks the SPC m localleader prefix
 ;; below. Scroll already lives on C-SPC. Clear both the base map and the
 ;; evil state maps so general can install the SPC m prefix.
 (keymap-set org-agenda-mode-map "SPC" nil)
 (when (fboundp 'evil-define-key*)
   (dolist (state '(normal visual motion))
     (when (boundp 'org-agenda-mode-map)
       (condition-case nil
           (evil-define-key* state org-agenda-mode-map (kbd "SPC") nil)
         (error nil)))))
 (general-define-key
  :keymaps 'org-agenda-mode-map
  :states '(normal visual motion)
  :prefix luna-localleader-key
  "q" '(org-agenda-set-tags :wk "set tags")
  "r" '(org-agenda-refile :wk "refile")
  "t" '(org-agenda-todo :wk "todo"))
 (general-define-key
  :keymaps 'org-agenda-mode-map
  :states '(normal visual motion)
  :prefix (concat luna-localleader-key " d")
  "d" '(org-agenda-deadline :wk "deadline")
  "s" '(org-agenda-schedule :wk "schedule"))
 (general-define-key
  :keymaps 'org-agenda-mode-map
  :states '(normal visual motion)
  :prefix (concat luna-localleader-key " c")
  "c" '(org-agenda-clock-cancel :wk "clock cancel")
  "g" '(org-agenda-clock-goto :wk "clock goto")
  "i" '(org-agenda-clock-in :wk "clock in")
  "o" '(org-agenda-clock-out :wk "clock out")
  "r" '(org-agenda-clockreport-mode :wk "clock report mode")
  "s" '(org-agenda-show-clocking-issues :wk "clocking issues"))
 (general-define-key
  :keymaps 'org-agenda-mode-map
  :states '(normal visual motion)
  :prefix (concat luna-localleader-key " p")
  "d" '(org-agenda-priority-down :wk "priority down")
  "p" '(org-agenda-priority :wk "priority")
  "u" '(org-agenda-priority-up :wk "priority up")))
(after! evil-org
  (let-alist evil-org-movement-bindings
    (let ((Cright  (concat "C-" .right))
          (Cleft   (concat "C-" .left))
          (Cup     (concat "C-" .up))
          (Cdown   (concat "C-" .down))
          (CSright (concat "C-S-" .right))
          (CSleft  (concat "C-S-" .left))
          (CSup    (concat "C-S-" .up))
          (CSdown  (concat "C-S-" .down)))
      (general-define-key
       :keymaps 'evil-org-mode-map
       :states '(normal insert)
       [C-return]   #'+org/insert-item-below
       [C-S-return] #'+org/insert-item-above)
      (unless evil-disable-insert-state-bindings
        (general-define-key
         :keymaps 'evil-org-mode-map
         :states '(insert)
         Cright (lambda () (interactive) (if (org-at-table-p) (org-table-next-field) (org-end-of-line)))
         Cleft  (lambda () (interactive) (if (org-at-table-p) (org-table-previous-field) (org-beginning-of-line)))
         Cup    (lambda () (interactive) (if (org-at-table-p) (+org/table-previous-row) (org-up-element)))
         Cdown  (lambda () (interactive) (if (org-at-table-p) (org-table-next-row) (org-down-element)))
         CSright   #'org-shiftright
         CSleft    #'org-shiftleft
         CSup      #'org-shiftup
         CSdown    #'org-shiftdown
         "RET"     #'+org/return
         [S-return] #'+org/shift-return
         "S-RET"   #'+org/shift-return))
      (general-define-key
       :keymaps 'evil-org-mode-map
       :states '(normal)
       CSright   #'org-shiftright
       CSleft    #'org-shiftleft
       CSup      #'org-shiftup
       CSdown    #'org-shiftdown
       "gQ"  #'+org/reformat-at-point
       "za"  #'+org/toggle-fold
       "zA"  #'org-shifttab
       "zc"  #'+org/close-fold
       "zC"  #'outline-hide-subtree
       "zm"  #'+org/hide-next-fold-level
       "zM"  #'+org/close-all-folds
       "zn"  #'org-tree-to-indirect-buffer
       "zo"  #'+org/open-fold
       "zO"  #'outline-show-subtree
       "zr"  #'+org/show-next-fold-level
       "zR"  #'+org/open-all-folds
       "zi"  #'org-toggle-inline-images)
      (general-define-key
       :keymaps 'evil-org-mode-map
       :states '(motion)
       "RET"  #'+org/dwim-at-point
       "]h"  #'org-forward-heading-same-level
       "[h"  #'org-backward-heading-same-level
       "]l"  #'org-next-link
       "[l"  #'org-previous-link
       "]c"  #'org-babel-next-src-block
       "[c"  #'org-babel-previous-src-block)
      (general-define-key
       :keymaps 'org-read-date-minibuffer-local-map
       Cleft    (cmd! (org-eval-in-calendar '(calendar-backward-day 1)))
       Cright   (cmd! (org-eval-in-calendar '(calendar-forward-day 1)))
       Cup      (cmd! (org-eval-in-calendar '(calendar-backward-week 1)))
       Cdown    (cmd! (org-eval-in-calendar '(calendar-forward-week 1)))
       CSleft   (cmd! (org-eval-in-calendar '(calendar-backward-month 1)))
       CSright  (cmd! (org-eval-in-calendar '(calendar-forward-month 1)))
       CSup     (cmd! (org-eval-in-calendar '(calendar-backward-year 1)))
       CSdown   (cmd! (org-eval-in-calendar '(calendar-forward-year 1)))))))
(after! evil-org-agenda
  (when (boundp 'evil-org-agenda-mode-map)
    (evil-define-key* 'motion evil-org-agenda-mode-map
      (kbd luna-leader-key) nil)))

;; --- emacs-lisp (framework/lang/emacs-lisp.el) -----------------------
(after! helpful
  (global-set-key [remap describe-function] #'helpful-callable)
  (global-set-key [remap describe-command]  #'helpful-command)
  (global-set-key [remap describe-variable] #'helpful-variable)
  (global-set-key [remap describe-key]      #'helpful-key)
  (general-define-key
   :keymaps 'helpful-mode-map
   :states '(normal motion)
   "o" '(link-hint-open-link :wk "open link")
   "gr" '(helpful-update :wk "refresh")
   "C-o" '(#'+emacs-lisp/helpful-previous :wk "previous")
   "l" '(#'+emacs-lisp/helpful-previous :wk "previous")
   "r" '(#'+emacs-lisp/helpful-next :wk "next")
   [C-i] '(#'+emacs-lisp/helpful-next :wk "next")
   "<" '(#'+emacs-lisp/helpful-previous :wk "previous")
   ">" '(#'+emacs-lisp/helpful-next :wk "next"))
  (general-define-key
   :keymaps 'helpful-mode-map
   "C-c C-b" #'+emacs-lisp/helpful-previous
   "C-c C-f" #'+emacs-lisp/helpful-next))
(general-define-key
 :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
 :states '(normal visual motion)
 :prefix luna-localleader-key
 "b" '(#'+emacs-lisp/change-working-buffer :wk "Set working buffer")
 "m" '(macrostep-expand :wk "Expand macro"))
(general-define-key
 :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
 :states '(normal visual motion)
 :prefix (concat luna-localleader-key " d")
 "f" '(#'+emacs-lisp/edebug-instrument-defun-on :wk "debug defun on")
 "F" '(#'+emacs-lisp/edebug-instrument-defun-off :wk "debug defun off"))
(general-define-key
 :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
 :states '(normal visual motion)
 :prefix (concat luna-localleader-key " e")
 "b" '(eval-buffer :wk "eval buffer")
 "d" '(eval-defun :wk "eval defun")
 "e" '(eval-last-sexp :wk "eval last sexp")
 "r" '(eval-region :wk "eval region")
 "l" '(load-library :wk "load library"))
(general-define-key
 :keymaps '(emacs-lisp-mode-map lisp-interaction-mode-map)
 :states '(normal visual motion)
 :prefix (concat luna-localleader-key " g")
 "f" '(find-function :wk "find function")
 "v" '(find-variable :wk "find variable")
 "l" '(find-library :wk "find library"))
(after! buttercup
  (general-define-key
   :keymaps 'buttercup-minor-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " t")
   "t" '(#'+emacs-lisp/buttercup-run-file :wk "run file")
   "a" '(#'+emacs-lisp/buttercup-run-project :wk "run project")
   "s" '(buttercup-run-at-point :wk "run at point")))

;; --- git (framework/tools/magit.el) ----------------------------------
(after! forge
  (evil-define-key 'normal forge-topic-list-mode-map "q" #'kill-current-buffer)
  (when (not forge-add-default-bindings)
    (define-key magit-mode-map [remap magit-browse-thing] #'forge-browse)
    (define-key magit-remote-section-map [remap magit-browse-thing] #'forge-browse-remote)
    (define-key magit-branch-section-map [remap magit-browse-thing] #'forge-browse-branch)))

;; --- pass / pdf / lsp ------------------------------------------------
(after! pass
  (evil-define-key 'normal pass-mode-map
    "j"   #'pass-next-entry
    "k"   #'pass-prev-entry
    "d"   #'pass-kill
    (kbd "C-j") #'pass-next-directory
    (kbd "C-k") #'pass-prev-directory))
(after! pdf-view
  (map! :map pdf-view-mode-map :gn "q" #'kill-current-buffer))
(after! lsp-mode
  (map! :map lsp-mode-map [remap xref-find-apropos] #'consult-lsp-symbols))

;; --- web / css / json (framework/lang/{javascript,markdown}.el) ------
(after! css-mode
  (general-define-key
   :keymaps '(css-mode-map scss-mode-map less-css-mode-map)
   :states '(normal visual motion)
   :prefix luna-localleader-key
   "rb" '(#'+css/toggle-inline-or-block :wk "toggle inline/block")))
(after! json-mode
  (general-define-key
   :keymaps 'json-mode-map
   :states '(normal visual motion)
   :prefix luna-localleader-key
   "p" '(json-mode-show-path :wk "show path")
   "t" '(json-toggle-boolean :wk "toggle boolean")
   "d" '(json-mode-kill-path :wk "kill path")
   "x" '(json-nullify-sexp :wk "nullify sexp")
   "+" '(json-increment-number-at-point :wk "increment number")
   "-" '(json-decrement-number-at-point :wk "decrement number")
   "f" '(json-mode-beautify :wk "beautify")))

;; --- UI (framework/ui/*.el) ------------------------------------------
;; dashboard provides no feature (loader strips provides), so hook the mode
;; to bind once its keymap exists.
(add-hook '+dashboard-mode-hook
          (lambda ()
            (map! :map +dashboard-mode-map
                  [left-margin mouse-1]   #'ignore
                  [remap forward-button]  #'+dashboard/forward-button
                  [remap backward-button] #'+dashboard/backward-button
                  [remap push-button]     #'+dashboard/push-button
                  "n"       #'forward-button
                  "p"       #'backward-button
                  "C-n"     #'forward-button
                  "C-p"     #'backward-button
                  [down]    #'forward-button
                  [up]      #'backward-button
                  [tab]     #'forward-button
                  [backtab] #'backward-button
                  ;; Evil remaps
                  [remap evil-next-line]     #'forward-button
                  [remap evil-previous-line] #'backward-button
                  [remap evil-next-visual-line]     #'forward-button
                  [remap evil-previous-visual-line] #'backward-button
                  [remap evil-paste-pop-next] #'forward-button
                  [remap evil-paste-pop]      #'backward-button
                  [remap evil-delete]         #'ignore
                  [remap evil-delete-line]    #'ignore
                  [remap evil-insert]         #'ignore
                  [remap evil-append]         #'ignore
                  [remap evil-replace]        #'ignore
                  [remap evil-enter-replace-state] #'ignore
                  [remap evil-change]         #'ignore
                  [remap evil-change-line]    #'ignore
                  [remap evil-visual-char]    #'ignore
                  [remap evil-visual-line]    #'ignore)))
(after! persp-mode
  (map! :map persp-mode-map
        [remap delete-window] #'+workspace/close-window-or-workspace
        [remap evil-window-delete] #'+workspace/close-window-or-workspace))
(after! winum
  (map! :map evil-window-map
        "0" #'winum-select-window-0-or-10
        "1" #'winum-select-window-1
        "2" #'winum-select-window-2
        "3" #'winum-select-window-3
        "4" #'winum-select-window-4
        "5" #'winum-select-window-5
        "6" #'winum-select-window-6
        "7" #'winum-select-window-7
        "8" #'winum-select-window-8
        "9" #'winum-select-window-9))
(after! diff-hl
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
          :n "S" #'diff-hl-show-hunk-stage-hunk)))

;; --- irc / rss (framework/app/*.el) ----------------------------------
(after! circe
  (define-key circe-mode-map [remap kill-buffer] #'bury-buffer)
  (general-def :keymaps 'circe-mode-map :prefix luna-localleader-key
    "a" #'tracking-next-buffer
    "j" #'circe-command-JOIN
    "m" #'+irc/send-message
    "p" #'circe-command-PART
    "Q" #'+irc/quit
    "R" #'circe-reconnect
    "c" #'+irc/jump-to-channel)
  (general-def :keymaps 'circe-channel-mode-map :prefix luna-localleader-key
    "n" #'circe-command-NAMES))
(after! lui
  (define-key lui-mode-map "\C-u" #'lui-kill-to-beginning-of-line))
(global-set-key [remap tracking-next-buffer] #'+irc/tracking-next-buffer)
(after! elfeed-show
  (define-key elfeed-show-mode-map [remap next-buffer] #'+rss/next)
  (define-key elfeed-show-mode-map [remap previous-buffer] #'+rss/previous))
(after! elfeed-search
  (when (modulep! :editor evil +everywhere)
    (evil-define-key 'normal elfeed-search-mode-map
      "q" #'kill-current-buffer
      "r" #'revert-buffer
      (kbd "M-RET") #'elfeed-search-browse-url)
    (map! :map elfeed-show-mode-map
          :n "gc" nil
          :n "gc" #'+rss/copy-link)))

;; --- calendar (framework/app/calendar.el) ----------------------------
(after! calfw
  (define-key calfw-calendar-mode-map "q" #'+calendar/quit)
  (map! :map calfw-calendar-mode-map
        :m "q"   #'+calendar/quit
        :m "SPC" #'calfw-show-details-command
        :m "RET" #'calfw-show-details-command
        :m "TAB"     #'calfw-navi-prev-item-command
        :m [tab]     #'calfw-navi-prev-item-command
        :m [backtab] #'calfw-navi-next-item-command
        :m "$"   #'calfw-navi-goto-week-end-command
        :m "."   #'calfw-navi-goto-today-command
        :m "<"   #'calfw-navi-previous-month-command
        :m ">"   #'calfw-navi-next-month-command
        :m "C-h" #'calfw-navi-previous-month-command
        :m "C-l" #'calfw-navi-next-month-command
        :m "D"   #'calfw-change-view-day
        :m "M"   #'calfw-change-view-month
        :m "T"   #'calfw-change-view-two-weeks
        :m "W"   #'calfw-change-view-week
        :m "^"   #'calfw-navi-goto-week-begin-command
        :m "gr"  #'calfw-refresh-calendar-buffer
        :m "h"   #'calfw-navi-previous-day-command
        :m "H"   #'calfw-navi-goto-first-date-command
        :m "j"   #'calfw-navi-next-week-command
        :m "k"   #'calfw-navi-previous-week-command
        :m "l"   #'calfw-navi-next-day-command
        :m "L"   #'calfw-navi-goto-last-date-command
        :m "t"   #'calfw-navi-goto-today-command)
  (map! :map calfw-details-mode-map
        :m "SPC" #'calfw-details-kill-buffer-command
        :m "RET" #'calfw-details-kill-buffer-command
        :m "TAB"     #'calfw-details-navi-prev-item-command
        :m [tab]     #'calfw-details-navi-prev-item-command
        :m [backtab] #'calfw-details-navi-next-item-command
        :m "q"   #'calfw-details-kill-buffer-command
        :m "C-h" #'calfw-details-navi-prev-command
        :m "C-l" #'calfw-details-navi-next-command
        :m "C-k" #'calfw-details-navi-prev-item-command
        :m "C-j" #'calfw-details-navi-next-item-command))

;; --- python (framework/lang/python.el) -------------------------------
(after! python
  (general-define-key
   :keymaps 'python-base-mode-map
   :states '(normal visual motion)
   :prefix luna-localleader-key
   "ta" '(python-pytest :wk "pytest")
   "tf" '(python-pytest-file-dwim :wk "pytest file dwim")
   "tF" '(python-pytest-file :wk "pytest file")
   "tt" '(python-pytest-run-def-or-class-at-point-dwim :wk "run def/class dwim")
   "tT" '(python-pytest-run-def-or-class-at-point :wk "run def/class")
   "tr" '(python-pytest-repeat :wk "pytest repeat")
   "tp" '(python-pytest-dispatch :wk "pytest dispatch"))
  (general-define-key
   :keymaps 'python-base-mode-map
   :states '(normal visual motion)
   :prefix (concat luna-localleader-key " e")
   "a" '(pipenv-activate :wk "activate")
   "d" '(pipenv-deactivate :wk "deactivate")
   "i" '(pipenv-install :wk "install")
   "l" '(pipenv-lock :wk "lock")
   "o" '(pipenv-open :wk "open module")
   "r" '(pipenv-run :wk "run")
   "s" '(pipenv-shell :wk "shell")
   "u" '(pipenv-uninstall :wk "uninstall")))
(after! rustic
  (general-define-key
   :keymaps 'rustic-mode-map
   :states '(normal visual motion)
   :prefix luna-localleader-key
   "ba" '(#'+rust/cargo-audit :wk "cargo audit")
   "bb" '(rustic-cargo-build :wk "cargo build")
   "bB" '(rustic-cargo-bench :wk "cargo bench")
   "bc" '(rustic-cargo-check :wk "cargo check")
   "bC" '(rustic-cargo-clippy :wk "cargo clippy")
   "bd" '(rustic-cargo-build-doc :wk "cargo doc")
   "bD" '(rustic-cargo-doc :wk "cargo doc --open")
   "bf" '(rustic-cargo-fmt :wk "cargo fmt")
   "bn" '(rustic-cargo-new :wk "cargo new")
   "bo" '(rustic-cargo-outdated :wk "cargo outdated")
   "br" '(rustic-cargo-run :wk "cargo run")
   "ta" '(rustic-cargo-test :wk "cargo test all")
   "tt" '(rustic-cargo-current-test :wk "cargo test current")))

;; --- common-lisp (framework/lang/common-lisp.el) ---------------------
(after! sly
  (map! :map sly-db-mode-map
        :n "gr" #'sly-db-restart-frame)
  (map! :map sly-inspector-mode-map
        :n "gb" #'sly-inspector-pop
        :n "gr" #'sly-inspector-reinspect
        :n "gR" #'sly-inspector-fetch-all
        :n "K"  #'sly-inspector-describe-inspectee)
  (map! :map sly-xref-mode-map
        :n "gr" #'sly-recompile-xref
        :n "gR" #'sly-recompile-all-xrefs))
(general-def :keymaps 'lisp-mode-map :prefix luna-localleader-key
  "'" #'sly
  ";" (cmd!! #'sly '-)
  "m" #'macrostep-expand
  "f" #'+lisp/find-file-in-quicklisp)
(general-def :keymaps 'lisp-mode-map
  :prefix (concat luna-localleader-key " c")
  "c" #'sly-compile-file
  "C" #'sly-compile-and-load-file
  "f" #'sly-compile-defun
  "l" #'sly-load-file
  "n" #'sly-remove-notes
  "r" #'sly-compile-region)
(general-def :keymaps 'lisp-mode-map
  :prefix (concat luna-localleader-key " e")
  "b" #'sly-eval-buffer
  "d" #'sly-overlay-eval-defun
  "e" #'sly-eval-last-expression
  "E" #'sly-eval-print-last-expression
  "f" #'sly-eval-defun
  "F" #'sly-undefine-function
  "r" #'sly-eval-region)
(general-def :keymaps 'lisp-mode-map
  :prefix (concat luna-localleader-key " g")
  "b" #'sly-pop-find-definition-stack
  "d" #'sly-edit-definition
  "D" #'sly-edit-definition-other-window
  "n" #'sly-next-note
  "N" #'sly-previous-note
  "s" #'sly-stickers-next-sticker
  "S" #'sly-stickers-prev-sticker)
(general-def :keymaps 'lisp-mode-map
  :prefix (concat luna-localleader-key " h")
  "<" #'sly-who-calls
  ">" #'sly-calls-who
  "~" #'hyperspec-lookup-format
  "#" #'hyperspec-lookup-reader-macro
  "a" #'sly-apropos
  "b" #'sly-who-binds
  "d" #'sly-disassemble-symbol
  "h" #'sly-describe-symbol
  "H" #'sly-hyperspec-lookup
  "m" #'sly-who-macroexpands
  "p" #'sly-apropos-package
  "r" #'sly-who-references
  "s" #'sly-who-specializes
  "S" #'sly-who-sets)
(general-def :keymaps 'lisp-mode-map
  :prefix (concat luna-localleader-key " r")
  "c" #'sly-mrepl-clear-repl
  "l" #'sly-asdf-load-system
  "q" #'sly-quit-lisp
  "r" #'sly-restart-inferior-lisp
  "R" #'+lisp/reload-project
  "s" #'sly-mrepl-sync)
(general-def :keymaps 'lisp-mode-map
  :prefix (concat luna-localleader-key " s")
  "b" #'sly-stickers-toggle-break-on-stickers
  "c" #'sly-stickers-clear-defun-stickers
  "C" #'sly-stickers-clear-buffer-stickers
  "f" #'sly-stickers-fetch
  "r" #'sly-stickers-replay
  "s" #'sly-stickers-dwim)
(general-def :keymaps 'lisp-mode-map
  :prefix (concat luna-localleader-key " t")
  "s" #'sly-asdf-test-system)
(general-def :keymaps 'lisp-mode-map
  :prefix (concat luna-localleader-key " T")
  "t" #'sly-toggle-trace-fdefinition
  "T" #'sly-toggle-fancy-trace
  "u" #'sly-untrace-all)
(map! :map lisp-mode-map
      :n "gb" #'sly-pop-find-definition-stack)

;; --- ruby (framework/lang/ruby.el) -----------------------------------
(after! ruby-mode
  (general-def :keymaps 'ruby-mode-map :prefix luna-localleader-key
    "J" #'ruby-json-to-hash-parse-json
    "j" #'ruby-json-to-hash-toggle-let)
  (general-def :keymaps 'ruby-mode-map
    :prefix (concat luna-localleader-key " k")
    "k" #'rake
    "r" #'rake-rerun
    "R" #'rake-regenerate-cache
    "f" #'rake-find-task))
(after! rspec-mode
  (general-def :keymaps '(rspec-verifiable-mode-map rspec-dired-mode-map rspec-mode-map)
    :prefix (concat luna-localleader-key " t")
    "a" #'rspec-verify-all
    "r" #'rspec-rerun)
  (general-def :keymaps '(rspec-verifiable-mode-map rspec-mode-map)
    :prefix (concat luna-localleader-key " t")
    "v" #'rspec-verify
    "c" #'rspec-verify-continue
    "l" #'rspec-run-last-failed
    "T" #'rspec-toggle-spec-and-target
    "t" #'rspec-toggle-spec-and-target-find-example)
  (general-def :keymaps 'rspec-verifiable-mode-map
    :prefix (concat luna-localleader-key " t")
    "f" #'rspec-verify-method
    "m" #'rspec-verify-matching)
  (general-def :keymaps 'rspec-mode-map
    :prefix (concat luna-localleader-key " t")
    "s" #'rspec-verify-single
    "e" #'rspec-toggle-example-pendingness)
  (general-def :keymaps 'rspec-dired-mode-map
    :prefix (concat luna-localleader-key " t")
    "v" #'rspec-dired-verify
    "s" #'rspec-dired-verify-single))
(after! minitest
  (general-def :keymaps 'minitest-mode-map
    :prefix (concat luna-localleader-key " t")
    "r" #'minitest-rerun
    "a" #'minitest-verify-all
    "s" #'minitest-verify-single
    "v" #'minitest-verify))

;; --- agda (framework/lang/agda.el) -----------------------------------
(after! agda2-mode
  (general-def :keymaps 'agda2-mode-map :prefix luna-localleader-key
    "?"   #'agda2-show-goals
    "."   #'agda2-goal-and-context-and-inferred
    ","   #'agda2-goal-and-context
    "="   #'agda2-show-constraints
    "SPC" #'agda2-give
    "a"   #'agda2-mimer-maybe-all
    "b"   #'agda2-previous-goal
    "c"   #'agda2-make-case
    "d"   #'agda2-infer-type-maybe-toplevel
    "e"   #'agda2-show-context
    "f"   #'agda2-next-goal
    "gG"  #'agda2-go-back
    "h"   #'agda2-helper-function-type
    "l"   #'agda2-load
    "n"   #'agda2-compute-normalised-maybe-toplevel
    "p"   #'agda2-module-contents-maybe-toplevel
    "r"   #'agda2-refine
    "s"   #'agda2-solveAll
    "t"   #'agda2-goal-type
    "w"   #'agda2-why-in-scope-maybe-toplevel)
  (general-def :keymaps 'agda2-mode-map
    :prefix (concat luna-localleader-key " x")
    "c"   #'agda2-compile
    "d"   #'agda2-remove-annotations
    "h"   #'agda2-display-implicit-arguments
    "q"   #'agda2-quit
    "r"   #'agda2-restart))

;; --- php (framework/lang/php.el) -------------------------------------
(after! composer
  (map! :map +php-common-mode-map
        "c" #'composer
        "i" #'composer-install
        "r" #'composer-require
        "u" #'composer-update
        "d" #'composer-dump-autoload
        "s" #'composer-run-script
        "v" #'composer-run-vendor-bin-command
        "o" #'composer-find-json-file
        "l" #'composer-view-lock-file)
  (after! php-mode
    (general-def :keymaps 'php-mode-map :prefix luna-localleader-key
      "c" +php-common-mode-map))
  (after! php-ts-mode
    (general-def :keymaps 'php-ts-mode-map :prefix luna-localleader-key
      "c" +php-common-mode-map)))
(after! php-mode
  (general-def :keymaps 'php-mode-map
    :prefix (concat luna-localleader-key " t")
    "r" #'phpunit-current-project
    "a" #'phpunit-current-class
    "s" #'phpunit-current-test))
(after! php-refactor-mode
  (general-def :keymaps 'php-refactor-mode-map
    :prefix (concat luna-localleader-key " r")
    "cv" #'php-refactor--convert-local-to-instance-variable
    "u"  #'php-refactor--optimize-use
    "xm" #'php-refactor--extract-method
    "rv" #'php-refactor--rename-local-variable))

;; --- latex (framework/lang/latex.el) ---------------------------------
(after! latex
  (general-def :keymaps 'latex-mode-map :prefix luna-localleader-key
    "v" #'TeX-view
    "c" #'+latex/compile
    "a" #'TeX-command-run-all
    "m" #'TeX-command-master)
  (general-def :keymaps 'LaTeX-mode-map :prefix luna-localleader-key
    "v" #'TeX-view
    "c" #'+latex/compile
    "a" #'TeX-command-run-all
    "m" #'TeX-command-master
    "p" #'preview-at-point
    "P" #'preview-clearout-at-point))
(after! cdlatex
  (map! :map cdlatex-mode-map
        "$" nil
        "(" nil
        "{" nil
        "[" nil
        "|" nil
        "<" nil
        "TAB" nil
        "^" nil
        "_" nil
        [control return] nil))
(after! reftex
  (general-def :keymaps 'reftex-mode-map :prefix luna-localleader-key
    ";" 'reftex-toc))
(after! bibtex
  (define-key bibtex-mode-map (kbd "C-c \\") #'bibtex-fill-entry))

;; --- go / nix / markdown (framework/lang/{rust,nix,sh}.el) -----------
(after! go-mode
  (general-define-key
   :keymaps 'go-mode-map :states '(normal visual motion)
   :prefix luna-localleader-key
   "a" '(go-tag-add :wk "add struct tags")
   "d" '(go-tag-remove :wk "remove struct tags")
   "e" '(#'+go/play-buffer-or-region :wk "play buffer/region")
   "i" '(go-goto-imports :wk "go to imports")
   "h." '(godoc-at-point :wk "godoc at point")
   "ria" '(go-import-add :wk "add import")
   "br" '(cmd! (compile "go run .") :wk "go run .")
   "bb" '(cmd! (compile "go build") :wk "go build")
   "bc" '(cmd! (compile "go clean") :wk "go clean")
   "gf" '(#'+go/generate-file :wk "go generate file")
   "gd" '(#'+go/generate-dir :wk "go generate dir")
   "ga" '(#'+go/generate-all :wk "go generate all")
   "tt" '(#'+go/test-rerun :wk "rerun last test")
   "ta" '(#'+go/test-all :wk "test all")
   "ts" '(#'+go/test-single :wk "test single")
   "tn" '(#'+go/test-nested :wk "test nested")
   "tf" '(#'+go/test-file :wk "test file")
   "tg" '(go-gen-test-dwim :wk "gen test dwim")
   "tG" '(go-gen-test-all :wk "gen test all")
   "te" '(go-gen-test-exported :wk "gen test exported")
   "tbs" '(#'+go/bench-single :wk "bench single")
   "tba" '(#'+go/bench-all :wk "bench all")))
(after! go-ts-mode
  (general-define-key
   :keymaps 'go-ts-mode-map :states '(normal visual motion)
   :prefix luna-localleader-key
   "a" '(go-tag-add :wk "add struct tags")
   "d" '(go-tag-remove :wk "remove struct tags")
   "e" '(#'+go/play-buffer-or-region :wk "play buffer/region")
   "i" '(go-goto-imports :wk "go to imports")
   "h." '(godoc-at-point :wk "godoc at point")
   "ria" '(go-import-add :wk "add import")
   "br" '(cmd! (compile "go run .") :wk "go run .")
   "bb" '(cmd! (compile "go build") :wk "go build")
   "bc" '(cmd! (compile "go clean") :wk "go clean")
   "gf" '(#'+go/generate-file :wk "go generate file")
   "gd" '(#'+go/generate-dir :wk "go generate dir")
   "ga" '(#'+go/generate-all :wk "go generate all")
   "tt" '(#'+go/test-rerun :wk "rerun last test")
   "ta" '(#'+go/test-all :wk "test all")
   "ts" '(#'+go/test-single :wk "test single")
   "tn" '(#'+go/test-nested :wk "test nested")
   "tf" '(#'+go/test-file :wk "test file")
   "tg" '(go-gen-test-dwim :wk "gen test dwim")
   "tG" '(go-gen-test-all :wk "gen test all")
   "te" '(go-gen-test-exported :wk "gen test exported")
   "tbs" '(#'+go/bench-single :wk "bench single")
   "tba" '(#'+go/bench-all :wk "bench all")))
(after! nix-mode
  (general-define-key
   :keymaps 'nix-mode-map :states '(normal visual motion)
   :prefix luna-localleader-key
   "f" '(nix-update-fetch :wk "update fetch")
   "p" '(nix-format-buffer :wk "format buffer")
   "r" '(nix-repl-show :wk "repl")
   "s" '(nix-shell :wk "shell")
   "b" '(nix-build :wk "build")
   "u" '(nix-unpack :wk "unpack")
   "o" '(#'+nix/lookup-option :wk "lookup option")))
(after! nix-ts-mode
  (general-define-key
   :keymaps 'nix-ts-mode-map :states '(normal visual motion)
   :prefix luna-localleader-key
   "f" '(nix-update-fetch :wk "update fetch")
   "p" '(nix-format-buffer :wk "format buffer")
   "r" '(nix-repl-show :wk "repl")
   "s" '(nix-shell :wk "shell")
   "b" '(nix-build :wk "build")
   "u" '(nix-unpack :wk "unpack")
   "o" '(#'+nix/lookup-option :wk "lookup option")))
(after! markdown-mode
  (general-define-key
   :keymaps 'markdown-mode-map :states '(normal visual motion)
   :prefix luna-localleader-key
   "'" '(markdown-edit-code-block :wk "edit code block")
   "o" '(markdown-open :wk "open")
   "p" '(markdown-preview :wk "preview")
   "e" '(markdown-export :wk "export")
   "iT" '(markdown-toc-generate-toc :wk "table of contents")
   "ii" '(markdown-insert-image :wk "image")
   "il" '(markdown-insert-link :wk "link")
   "i-" '(markdown-insert-hr :wk "hr")
   "i1" '(markdown-insert-header-atx-1 :wk "heading 1")
   "i2" '(markdown-insert-header-atx-2 :wk "heading 2")
   "i3" '(markdown-insert-header-atx-3 :wk "heading 3")
   "i4" '(markdown-insert-header-atx-4 :wk "heading 4")
   "i5" '(markdown-insert-header-atx-5 :wk "heading 5")
   "i6" '(markdown-insert-header-atx-6 :wk "heading 6")
   "iC" '(markdown-insert-gfm-code-block :wk "code block")
   "iP" '(markdown-pre-region :wk "pre region")
   "iQ" '(markdown-blockquote-region :wk "blockquote region")
   "i[" '(markdown-insert-gfm-checkbox :wk "checkbox")
   "ib" '(markdown-insert-bold :wk "bold")
   "ic" '(markdown-insert-code :wk "inline code")
   "tf" '(markdown-toggle-fontify-code-blocks-natively :wk "code highlights")
   "ti" '(markdown-toggle-inline-images :wk "inline images")
   "tl" '(markdown-toggle-url-hiding :wk "url hiding")
   "tm" '(markdown-toggle-markup-hiding :wk "markup hiding")
   "tw" '(markdown-toggle-wiki-links :wk "wiki links")
   "tx" '(markdown-toggle-gfm-checkbox :wk "gfm checkbox"))
  (when (modulep! +grip)
    (general-define-key
     :keymaps 'markdown-mode-map :states '(normal visual motion)
     :prefix luna-localleader-key
     "p" '(grip-mode :wk "grip preview"))))
(after! evil-markdown
  (general-define-key
   :keymaps 'evil-markdown-mode-map
   :states '(normal)
   "TAB" #'markdown-cycle
   [backtab] #'markdown-shifttab
   "M-r" #'browse-url-of-file)
  (unless evil-disable-insert-state-bindings
    (general-define-key
     :keymaps 'evil-markdown-mode-map
     :states '(insert)
     "M-*" #'markdown-insert-list-item
     "M-b" #'markdown-insert-bold
     "M-i" #'markdown-insert-italic
     "M-`" #'+markdown/insert-del
     "M--" #'markdown-insert-hr))
  (general-define-key
   :keymaps 'evil-markdown-mode-map
   :states '(motion)
   "]h"  #'markdown-next-visible-heading
   "[h"  #'markdown-previous-visible-heading
   "[p"  #'markdown-promote
   "]p"  #'markdown-demote
   "[l"  #'markdown-previous-link
   "]l"  #'markdown-next-link))

;; --- lang: web-mode / emmet-mode (framework/lang/javascript.el) ------
(after! web-mode
  (general-define-key
   :keymaps 'web-mode-map
   :states '(normal visual motion)
   :prefix luna-localleader-key
   "h" '(web-mode-reload :wk "rehighlight buffer")
   "i" '(web-mode-buffer-indent :wk "indent buffer")
   "ab" '(web-mode-attribute-beginning :wk "attribute beginning")
   "ae" '(web-mode-attribute-end :wk "attribute end")
   "ai" '(web-mode-attribute-insert :wk "attribute insert")
   "an" '(web-mode-attribute-next :wk "attribute next")
   "as" '(web-mode-attribute-select :wk "attribute select")
   "ak" '(web-mode-attribute-kill :wk "attribute kill")
   "ap" '(web-mode-attribute-previous :wk "attribute previous")
   "at" '(web-mode-attribute-transpose :wk "attribute transpose")
   "bb" '(web-mode-block-beginning :wk "block beginning")
   "bc" '(web-mode-block-close :wk "block close")
   "be" '(web-mode-block-end :wk "block end")
   "bk" '(web-mode-block-kill :wk "block kill")
   "bn" '(web-mode-block-next :wk "block next")
   "bp" '(web-mode-block-previous :wk "block previous")
   "bs" '(web-mode-block-select :wk "block select")
   "da" '(web-mode-dom-apostrophes-replace :wk "dom apostrophes replace")
   "dd" '(web-mode-dom-errors-show :wk "dom errors show")
   "de" '(web-mode-dom-entities-encode :wk "dom entities encode")
   "dn" '(web-mode-dom-normalize :wk "dom normalize")
   "dq" '(web-mode-dom-quotes-replace :wk "dom quotes replace")
   "dt" '(web-mode-dom-traverse :wk "dom traverse")
   "dx" '(web-mode-dom-xpath :wk "dom xpath")
   "e/" '(web-mode-element-close :wk "element close")
   "ea" '(web-mode-element-content-select :wk "element content select")
   "eb" '(web-mode-element-beginning :wk "element beginning")
   "ec" '(web-mode-element-clone :wk "element clone")
   "ed" '(web-mode-element-child :wk "element child")
   "ee" '(web-mode-element-end :wk "element end")
   "ef" '(web-mode-element-children-fold-or-unfold :wk "element fold/unfold")
   "ei" '(web-mode-element-insert :wk "element insert")
   "ek" '(web-mode-element-kill :wk "element kill")
   "em" '(web-mode-element-mute-blanks :wk "element mute blanks")
   "en" '(web-mode-element-next :wk "element next")
   "ep" '(web-mode-element-previous :wk "element previous")
   "er" '(web-mode-element-rename :wk "element rename")
   "es" '(web-mode-element-select :wk "element select")
   "et" '(web-mode-element-transpose :wk "element transpose")
   "eu" '(web-mode-element-parent :wk "element parent")
   "ev" '(web-mode-element-vanish :wk "element vanish")
   "ew" '(web-mode-element-wrap :wk "element wrap")
   "ta" '(web-mode-tag-attributes-sort :wk "tag attributes sort")
   "tb" '(web-mode-tag-beginning :wk "tag beginning")
   "te" '(web-mode-tag-end :wk "tag end")
   "tm" '(web-mode-tag-match :wk "tag match")
   "tn" '(web-mode-tag-next :wk "tag next")
   "tp" '(web-mode-tag-previous :wk "tag previous")
   "ts" '(web-mode-tag-select :wk "tag select"))
  (general-define-key
   :keymaps 'web-mode-map
   :states '(insert)
   "SPC" #'self-insert-command)
  (general-define-key
   :keymaps 'web-mode-map
   :states '(normal)
   "za" #'web-mode-fold-or-unfold)
  (general-define-key
   :keymaps 'web-mode-map
   :states '(normal visual)
   "]a" #'web-mode-attribute-next
   "[a" #'web-mode-attribute-previous
   "]t" #'web-mode-tag-next
   "[t" #'web-mode-tag-previous
   "]T" #'web-mode-element-child
   "[T" #'web-mode-element-parent))
(after! emmet-mode
  (general-define-key
   :keymaps 'emmet-mode-keymap
   :states '(visual)
   [tab] #'emmet-wrap-with-markup)
  (general-define-key
   :keymaps 'emmet-mode-keymap
   [tab] #'+web/indent-or-yas-or-emmet-expand
   "M-E" #'emmet-expand-line))
(after! csv-mode
  (general-def :keymaps 'csv-mode-map :prefix luna-localleader-key
    "a" #'csv-align-fields
    "u" #'csv-unalign-fields
    "s" #'csv-sort-fields
    "S" #'csv-sort-numeric-fields
    "k" #'csv-kill-fields
    "t" #'csv-transpose))
(after! nael-mode
  (general-def :keymaps 'nael-mode-map :prefix luna-localleader-key
    "a" #'nael-abbrev-help
    "b" #'project-build
    "e" #'eldoc-doc-buffer))
(after! reftex-toc-mode
  (define-key reftex-toc-mode-map "j" #'next-line)
  (define-key reftex-toc-mode-map "k" #'previous-line)
  (define-key reftex-toc-mode-map "q" #'kill-buffer-and-window)
  (define-key reftex-toc-mode-map (kbd "ESC") #'kill-buffer-and-window))

(after! password-store
  (global-set-key (kbd "C-c p") #'password-store-copy))
(after! pass
  (evil-define-key 'normal pass-mode-map
    "j"   #'pass-next-entry
    "k"   #'pass-prev-entry
    "d"   #'pass-kill
    (kbd "C-j") #'pass-next-directory
    (kbd "C-k") #'pass-prev-directory))

;; --- misc (config/*.el, framework) -----------------------------------
(after! simple
  ;; Make SPC u SPC u [...] possible (doomemacs/core#747)
  (general-def :keymaps 'universal-argument-map :prefix luna-leader-key
    "u" #'universal-argument-more))
(after! tabulated-list
  (define-key tabulated-list-mode-map "q" #'quit-window))
(after! lnav
  (define-key lnav-mode-map (kbd "C-c") nil))

;;; keybind.el ends here
(provide 'keybind)
