;;; lang-extra-config.el --- doom :lang extras (agda, common-lisp, data, java,
;;; latex, lean, lua, php, qt, ruby)  -*- lexical-binding: t; -*-

;;; lang/agda
;; `agda2-mode' ships with Agda itself, not as a standalone nixpkgs emacs
;; package. With the +local flag this module loads agda-mode from the locally
;; installed Agda instead, so the package is skipped. (nixpkgs does have
;; `emacsPackages.agda2-mode', but the +local path is authoritative for a
;; locally-installed Agda, and avoids version skew.)

(when (and (modulep! +local)
           (executable-find "agda-mode"))
  (add-to-list 'load-path
               (file-name-directory (shell-command-to-string "agda-mode locate")))
  (unless (require 'agda2 nil t)
    (message "Failed to find the `agda2' package")))

(after! agda2-mode
  ;; `set-lookup-handlers!' (doom +lookup) has no vanilla equivalent here;
  ;; agda2-mode provides its own xref-ish keybinds.
  (general-def :keymaps 'agda2-mode-map :prefix doom-localleader-key
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
    :prefix (concat doom-localleader-key " x")
    "c"   #'agda2-compile
    "d"   #'agda2-remove-annotations
    "h"   #'agda2-display-implicit-arguments
    "q"   #'agda2-quit
    "r"   #'agda2-restart))


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
  (setq sly-mrepl-history-file-name (doom-profile-cache-dir t "sly-mrepl-history")
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

  (map! :map sly-db-mode-map
        :n "gr" #'sly-db-restart-frame)
  (map! :map sly-inspector-mode-map
        :n "gb" #'sly-inspector-pop
        :n "gr" #'sly-inspector-reinspect
        :n "gR" #'sly-inspector-fetch-all
        :n "K"  #'sly-inspector-describe-inspectee)
  (map! :map sly-xref-mode-map
        :n "gr" #'sly-recompile-xref
        :n "gR" #'sly-recompile-all-xrefs)
  (map! :map lisp-mode-map
        :n "gb" #'sly-pop-find-definition-stack)

  (general-def :keymaps 'lisp-mode-map :prefix doom-localleader-key
    "'" #'sly
    ";" (cmd!! #'sly '-)
    "m" #'macrostep-expand
    "f" #'+lisp/find-file-in-quicklisp)
  (general-def :keymaps 'lisp-mode-map
    :prefix (concat doom-localleader-key " c")
    "c" #'sly-compile-file
    "C" #'sly-compile-and-load-file
    "f" #'sly-compile-defun
    "l" #'sly-load-file
    "n" #'sly-remove-notes
    "r" #'sly-compile-region)
  (general-def :keymaps 'lisp-mode-map
    :prefix (concat doom-localleader-key " e")
    "b" #'sly-eval-buffer
    "d" #'sly-overlay-eval-defun
    "e" #'sly-eval-last-expression
    "E" #'sly-eval-print-last-expression
    "f" #'sly-eval-defun
    "F" #'sly-undefine-function
    "r" #'sly-eval-region)
  (general-def :keymaps 'lisp-mode-map
    :prefix (concat doom-localleader-key " g")
    "b" #'sly-pop-find-definition-stack
    "d" #'sly-edit-definition
    "D" #'sly-edit-definition-other-window
    "n" #'sly-next-note
    "N" #'sly-previous-note
    "s" #'sly-stickers-next-sticker
    "S" #'sly-stickers-prev-sticker)
  (general-def :keymaps 'lisp-mode-map
    :prefix (concat doom-localleader-key " h")
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
    :prefix (concat doom-localleader-key " r")
    "c" #'sly-mrepl-clear-repl
    "l" #'sly-asdf-load-system
    "q" #'sly-quit-lisp
    "r" #'sly-restart-inferior-lisp
    "R" #'+lisp/reload-project
    "s" #'sly-mrepl-sync)
  (general-def :keymaps 'lisp-mode-map
    :prefix (concat doom-localleader-key " s")
    "b" #'sly-stickers-toggle-break-on-stickers
    "c" #'sly-stickers-clear-defun-stickers
    "C" #'sly-stickers-clear-buffer-stickers
    "f" #'sly-stickers-fetch
    "r" #'sly-stickers-replay
    "s" #'sly-stickers-dwim)
  (general-def :keymaps 'lisp-mode-map
    :prefix (concat doom-localleader-key " t")
    "s" #'sly-asdf-test-system)
  (general-def :keymaps 'lisp-mode-map
    :prefix (concat doom-localleader-key " T")
    "t" #'sly-toggle-trace-fdefinition
    "T" #'sly-toggle-fancy-trace
    "u" #'sly-untrace-all)

  (when (modulep! :editor evil +everywhere)
    (add-hook 'sly-mode-hook #'evil-normalize-keymaps)))

(defun +common-lisp-init-sly-h ()
  "Attempt to auto-start sly when opening a lisp buffer."
  (cond ((or (doom-temp-buffer-p (current-buffer))
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


;;; lang/data
;; yaml/json/nix live in lang-config.el (other submodules); lang/data only
;; contributes nxml-mode (xml/xsd/plist/rss) + csv-mode.

(leaf nxml-mode
  :ensure nil
  :defer t
  :mode ("\\.p\\(?:list\\|om\\)\\'"   ; plist, pom
         "\\.xs\\(?:d\\|lt\\)\\'"     ; xslt, xsd
         "\\.rss\\'")
  :config
  (setq nxml-slash-auto-complete-flag t
        nxml-auto-insert-xml-declaration-flag t)
  ;; https://github.com/Fuco1/smartparens/issues/397#issuecomment-501059014
  (after! smartparens
    (sp-local-pair 'nxml-mode "<" ">" :post-handlers '(("[d1]" "/")))))

(leaf csv-mode
  :ensure t
  :defer t
  :config
  (general-def :keymaps 'csv-mode-map :prefix doom-localleader-key
    "a" #'csv-align-fields
    "u" #'csv-unalign-fields
    "s" #'csv-sort-fields
    "S" #'csv-sort-numeric-fields
    "k" #'csv-kill-fields
    "t" #'csv-transpose))


;;; lang/java
(defvar +java-project-package-roots (list "java/" "test/" "main/" "src/" 1)
  "A list of relative directories (strings) or depths (integers) used by
`+java-current-package' to delimit the namespace from the current buffer's full
file path. Each root is tried in sequence until one is found.

If a directory is encountered in the file path, everything before it (including
it) will be ignored when converting the path into a namespace.

An integer depth is how many directories to pop off the start of the relative
file path (relative to the project root). e.g.

Say the absolute path is ~/some/project/src/java/net/lissner/game/MyClass.java
The project root is ~/some/project
If the depth is 1, the first directory in src/java/net/lissner/game/MyClass.java
  is removed: java.net.lissner.game.
If the depth is 2, the first two directories are removed: net.lissner.game.")

(after! projectile
  (add-to-list 'projectile-project-root-files "gradlew")
  (add-to-list 'projectile-project-root-files "settings.gradle"))

(defun +java-android-mode-maybe-h ()
  "Enable `android-mode' if this looks like an android project.

It determines this by the existence of AndroidManifest.xml or
src/main/AndroidManifest.xml."
  (when-let* ((root (doom-project-root)))
    (when (or (file-exists-p (expand-file-name "AndroidManifest.xml" root))
              (file-exists-p (expand-file-name "src/main/AndroidManifest.xml" root)))
      (android-mode +1))))

;;; java-mode (lsp-java)
;; doom gates this on `(modulep! +lsp) (modulep! :tools lsp -eglot)`; the compat
;; layer resolves those bare flags to nil today, but the task requires lsp-java,
;; so it is declared unconditionally. `set-indent-vars!' (doom) is dropped;
;; java-mode indents via `c-basic-offset' by default.
(leaf lsp-java
  :ensure t
  :defer t
  :config
  (setq lsp-java-workspace-dir (doom-profile-data-dir t "java-workspace"))
  (add-hook 'java-mode-hook #'lsp)
  (add-hook 'java-ts-mode-hook #'lsp)
  (when (modulep! :tools debugger +lsp)
    (setq lsp-jt-root (concat lsp-java-server-install-dir "java-test/server/")
          dap-java-test-runner (concat lsp-java-server-install-dir "test-runner/junit-platform-console-standalone.jar"))))

;; dap-java: gated on `:tools debugger +lsp` (nil in compat); dropped.

(leaf android-mode
  :ensure t
  :commands android-mode
  :init
  (dolist (hook '(java-mode-hook groovy-mode-hook nxml-mode-hook))
    (add-hook hook #'+java-android-mode-maybe-h)))

(leaf groovy-mode
  :ensure t
  :defer t
  :mode "\\.g\\(?:radle\\|roovy\\)\\'")


;;; lang/latex
(defcustom +latex-indent-item-continuation-offset 'align
  "Level to indent continuation of enumeration-type environments.

I.e., this affects \\item, \\enumerate, and \\description.

Set this to `align' for:

  \\item lines aligned
         like this.

Set to `auto' for continuation lines to be offset by `LaTeX-indent-line':

  \\item lines aligned
    like this, assuming `LaTeX-indent-line' == 2

Any other fixed integer will be added to `LaTeX-item-indent' and the current
indentation level.

Set this to `nil' to disable all this behavior.

You'll need to adjust `LaTeX-item-indent' to control indentation of \\item
itself."
  :type 'symbol)

(defcustom +latex-viewers '(skim evince sumatrapdf zathura okular pdf-tools)
  "A list of enabled LaTeX viewers to use, in this order.

If they don't exist, they will be ignored. Recognized viewers are skim, evince,
sumatrapdf, zathura, okular and pdf-tools."
  :type '(repeat (choice skim evince sumatrapdf zathura okular pdf-tools)))

;; HACK: doom sets `custom-dont-initialize' during the early parts of its
;;   startup process. This stops tex-site's setter on `TeX-modes' from
;;   activating in `tex-site', which auctex loads *very early* from its
;;   autoloads file. `tex-site's existence is hacky, so fix it as a one-off.
(after! tex-site
  (TeX-modes-set 'TeX-modes TeX-modes))

(after! tex
  ;; doom sets these at top level; they are moved here so the AUCTeX variables
  ;; exist (they are not autoloaded).
  (setq TeX-parse-self t ; parse on load
        TeX-auto-save t  ; parse on save
        ;; Use hidden directories for AUCTeX files.
        TeX-auto-local ".auctex-auto"
        TeX-style-local ".auctex-style"
        TeX-source-correlate-mode t
        TeX-source-correlate-method 'synctex
        ;; Don't start the Emacs server when correlating sources.
        TeX-source-correlate-start-server nil
        ;; Just save, don't ask before each compilation.
        TeX-save-query nil)

  ;; Fontify common LaTeX commands (doom +fontification.el).
  (setq font-latex-match-reference-keywords
        '(;; BibLaTeX.
          ("printbibliography" "[{")
          ("addbibresource" "[{")
          ;; Standard commands.
          ("cite" "[{")
          ("citep" "[{")
          ("citet" "[{")
          ("Cite" "[{")
          ("parencite" "[{")
          ("Parencite" "[{")
          ("footcite" "[{")
          ("footcitetext" "[{")
          ;; Style-specific commands.
          ("textcite" "[{")
          ("Textcite" "[{")
          ("smartcite" "[{")
          ("Smartcite" "[{")
          ("cite*" "[{")
          ("parencite*" "[{")
          ("supercite" "[{")
          ;; Qualified citation lists.
          ("cites" "[{")
          ("Cites" "[{")
          ("parencites" "[{")
          ("Parencites" "[{")
          ("footcites" "[{")
          ("footcitetexts" "[{")
          ("smartcites" "[{")
          ("Smartcites" "[{")
          ("textcites" "[{")
          ("Textcites" "[{")
          ("supercites" "[{")
          ;; Style-independent commands.
          ("autocite" "[{")
          ("Autocite" "[{")
          ("autocite*" "[{")
          ("Autocite*" "[{")
          ("autocites" "[{")
          ("Autocites" "[{")
          ;; Text commands.
          ("citeauthor" "[{")
          ("Citeauthor" "[{")
          ("citetitle" "[{")
          ("citetitle*" "[{")
          ("citeyear" "[{")
          ("citedate" "[{")
          ("citeurl" "[{")
          ;; Special commands.
          ("fullcite" "[{")
          ;; Cleveref.
          ("cref" "{")
          ("Cref" "{")
          ("cpageref" "{")
          ("Cpageref" "{")
          ("cpagerefrange" "{")
          ("Cpagerefrange" "{")
          ("crefrange" "{")
          ("Crefrange" "{")
          ("labelcref" "{")))
  (setq font-latex-match-textual-keywords
        '(;; BibLaTeX brackets.
          ("parentext" "{")
          ("brackettext" "{")
          ("hybridblockquote" "[{")
          ;; Auxiliary commands.
          ("textelp" "{")
          ("textelp*" "{")
          ("textins" "{")
          ("textins*" "{")
          ;; Subcaption.
          ("subcaption" "[{")))
  (setq font-latex-match-variable-keywords
        '(;; Amsmath.
          ("numberwithin" "{")
          ;; Enumitem.
          ("setlist" "[{")
          ("setlist*" "[{")
          ("newlist" "{")
          ("renewlist" "{")
          ("setlistdepth" "{")
          ("restartlist" "{")
          ("crefname" "{")))

  ;; Select viewer (doom +viewers.el; `letf!' not available, so a plain
  ;; helper is used instead).
  (let ((prepend (lambda (value)
                   (setq TeX-view-program-selection
                         (delete value TeX-view-program-selection))
                   (add-to-list 'TeX-view-program-selection value))))
    (dolist (viewer (reverse +latex-viewers))
      (pcase viewer
        (`skim
         (when (memq system-type '(darwin))
           (let ((app-path
                  (or (and (file-exists-p "/Applications/Skim.app") "/Applications/Skim.app")
                      (and (file-exists-p "~/Applications/Skim.app") "~/Applications/Skim.app"))))
             (when app-path
               (funcall prepend '(output-pdf "Skim"))
               (add-to-list 'TeX-view-program-list
                            (list "Skim" (format "%s/Contents/SharedSupport/displayline -r -b %%n %%o %%b"
                                                 app-path)))))))
        (`sumatrapdf
         (when (and (memq system-type '(windows-nt))
                    (executable-find "SumatraPDF"))
           (funcall prepend '(output-pdf "SumatraPDF"))))
        (`okular
         (when (executable-find "okular")
           ;; Configure Okular as viewer. Including a bug fix
           ;; (https://bugs.kde.org/show_bug.cgi?id=373855).
           (add-to-list 'TeX-view-program-list
                        '("Okular" ("okular --noraise --unique file:%o" (mode-io-correlate "#src:%n%a"))))
           (funcall prepend '(output-pdf "Okular"))))
        (`zathura
         (when (executable-find "zathura")
           (funcall prepend '(output-pdf "Zathura"))))
        (`evince
         (when (executable-find "evince")
           (funcall prepend '(output-pdf "Evince"))))
        (`pdf-tools
         (when (modulep! :tools pdf)
           (funcall prepend '(output-pdf "PDF Tools"))
           (when (memq system-type '(darwin))
             (add-to-list 'TeX-view-program-list '("PDF Tools" TeX-pdf-tools-sync-view)))
           (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer))))))

  ;; Do not prompt for a master file.
  (setq-default TeX-master t)
  ;; Set-up chktex.
  (setcar (cdr (assoc "Check" TeX-command-list)) "chktex -v6 -H %s")
  ;; Tell Emacs how to parse TeX files and not to auto-fill in math blocks.
  ;; (doom's `setq-hook!' was replaced with a plain lambda.)
  (add-hook 'TeX-mode-hook
            (lambda ()
              (setq-local fill-nobreak-predicate
                          (cons #'texmathp fill-nobreak-predicate))
              (when (boundp 'ispell-parser)
                (setq-local ispell-parser 'tex))))
  ;; Enable word wrapping.
  (add-hook 'TeX-mode-hook #'visual-line-mode)
  (after! smartparens-latex
    ;; We have to use lower case modes here, because `smartparens-mode' uses
    ;; the same during configuration.
    (let ((modes '(tex-mode plain-tex-mode latex-mode LaTeX-mode)))
      (dolist (open '(
                      ;; All these pairs dramatically slow down typing in LaTeX
                      ;; buffers, so remove them. Let snippets do their job.
                      "\\left(" "\\left[" "\\left\\{" "\\left|"
                      "\\bigl("   "\\biggl("   "\\Bigl("   "\\Biggl("
                      "\\bigl["   "\\biggl["   "\\Bigl["   "\\Biggl["
                      "\\bigl\\{" "\\biggl\\{" "\\Bigl\\{" "\\Biggl\\{"
                      "\\lfloor" "\\lceil" "\\langle"
                      "\\lVert" "\\lvert"
                      ;; Disable pairs that interfere with AucTeX,
                      ;; see https://github.com/Fuco1/smartparens/pull/1151.
                      "`" "``" "\""))
        ;; Some of the above pairs are in smartparens' global list, which
        ;; applies to all modes, so we need a local ':actions nil' override
        ;; (instead of ':actions :rem', which removes from the local list).
        (sp-local-pair modes open nil :actions nil))))
  ;; Define a function to compile the project.
  (defun +latex/compile ()
    (interactive)
    (TeX-save-document (TeX-master-file))
    (TeX-command TeX-command-default 'TeX-master-file -1))
  (general-def :keymaps 'latex-mode-map :prefix doom-localleader-key
    "v" #'TeX-view
    "c" #'+latex/compile
    "a" #'TeX-command-run-all
    "m" #'TeX-command-master)
  (with-eval-after-load 'latex
    (general-def :keymaps 'LaTeX-mode-map :prefix doom-localleader-key
      "v" #'TeX-view
      "c" #'+latex/compile
      "a" #'TeX-command-run-all
      "m" #'TeX-command-master)))

(after! latex
  ;; Add the TOC entry to the sectioning hooks.
  (setq LaTeX-section-hook
        '(LaTeX-section-heading
          LaTeX-section-title
          LaTeX-section-toc
          LaTeX-section-section
          LaTeX-section-label)
        LaTeX-fill-break-at-separators nil
        LaTeX-item-indent 0)
  ;; Provide proper indentation for LaTeX 'itemize', 'enumerate', and
  ;; 'description' environments.
  (dolist (env '("itemize" "enumerate" "description"))
    (add-to-list 'LaTeX-indent-environment-list `(,env +latex-indent-item-fn)))
  ;; Fix doomemacs/core#1849: allow fill-paragraph in itemize, enumerate, &
  ;; description.
  (defadvice! +latex--re-indent-itemize-and-enumerate-and-description-a (fn &rest args)
    :around #'LaTeX-fill-region-as-para-do
    (let ((LaTeX-indent-environment-list
           (append LaTeX-indent-environment-list
                   '(("itemize"     +latex-indent-item-fn)
                     ("enumerate"   +latex-indent-item-fn)
                     ("description" +latex-indent-item-fn)))))
      (apply fn args)))
  (defadvice! +latex--dont-indent-itemize-and-enumerate-and-description-a (fn &rest args)
    :around #'LaTeX-fill-region-as-paragraph
    (let ((LaTeX-indent-environment-list LaTeX-indent-environment-list))
      (dolist (item '("itemize" "enumerate" "description"))
        (setf (alist-get item LaTeX-indent-environment-list nil t #'equal) nil))
      (apply fn args))))

(defun +latex-indent-item-fn ()
  "Indent LaTeX \"itemize\",\"enumerate\", and \"description\" environments.

\"\\item\" is indented `LaTeX-indent-level' spaces relative to the beginning
of the environment.

See `LaTeX-indent-level-item-continuation' for the indentation strategy this
function uses."
  (save-match-data
    (let* ((re-beg "\\\\begin{")
           (re-end "\\\\end{")
           (re-env "\\(?:itemize\\|\\enumerate\\|description\\)")
           (indent (save-excursion
                     (when (looking-at (concat re-beg re-env "}"))
                       (end-of-line))
                     (LaTeX-find-matching-begin)
                     (+ LaTeX-item-indent (current-column))))
           (contin (pcase +latex-indent-item-continuation-offset
                     (`auto LaTeX-indent-level)
                     (`align 6)
                     (`nil (- LaTeX-indent-level))
                     (x x))))
      (cond ((looking-at (concat re-beg re-env "}"))
             (or (save-excursion
                   (beginning-of-line)
                   (ignore-errors
                     (LaTeX-find-matching-begin)
                     (+ (current-column)
                        LaTeX-item-indent
                        LaTeX-indent-level
                        (if (looking-at (concat re-beg re-env "}"))
                            contin
                          0))))
                 indent))
            ((looking-at (concat re-end re-env "}"))
             (save-excursion
               (beginning-of-line)
               (ignore-errors
                 (LaTeX-find-matching-begin)
                 (current-column))))
            ((looking-at "\\\\item")
             (+ LaTeX-indent-level indent))
            ((+ contin LaTeX-indent-level indent))))))

;; tex-fold: gated on `+fold` (nil in compat); dropped.

(leaf preview
  :ensure nil
  :hook (LaTeX-mode . LaTeX-preview-setup)
  :config
  (setq-default preview-scale 1.4
                preview-scale-function
                (lambda () (* (/ 10.0 (preview-document-pt)) preview-scale)))
  ;; Don't cache preamble, it creates issues with SyncTeX. Let users enable
  ;; caching if they have compilation times that long.
  (setq preview-auto-cache-preamble nil)
  (general-def :keymaps 'LaTeX-mode-map :prefix doom-localleader-key
    "p" #'preview-at-point
    "P" #'preview-clearout-at-point))

(leaf cdlatex
  :ensure t
  ;; doom gates this on `+cdlatex`; the compat resolves the bare flag to nil,
  ;; but +cdlatex is enabled in the registry and the task requires cdlatex.
  :hook (LaTeX-mode . cdlatex-mode)
  :hook (org-mode . org-cdlatex-mode)
  :config
  ;; Use \( ... \) instead of $ ... $.
  (setq cdlatex-use-dollar-to-ensure-math nil)
  ;; Disable keys that have overlapping functionality with other parts of the
  ;; config.
  (map! :map cdlatex-mode-map
        ;; Smartparens takes care of inserting closing delimiters.
        "$" nil
        "(" nil
        "{" nil
        "[" nil
        "|" nil
        "<" nil
        ;; TAB is used for CDLaTeX's snippets and navigation, but we have
        ;; Yasnippet for that.
        "TAB" nil
        ;; AUCTeX takes care of auto-inserting {} on _^ if you want, with
        ;; `TeX-electric-sub-and-superscript'.
        "^" nil
        "_" nil
        ;; AUCTeX already provides this with `LaTeX-insert-item'.
        [control return] nil))

;; Nicely indent lines that have wrapped when visual line mode is activated.
(leaf adaptive-wrap
  :ensure t
  :hook (LaTeX-mode . adaptive-wrap-prefix-mode)
  :init (setq-default adaptive-wrap-extra-indent 0))

(leaf evil-tex
  :ensure t
  :when (modulep! :editor evil +everywhere)
  :hook (LaTeX-mode . evil-tex-mode))

;; company-auctex / company-math / company-reftex: gated on `:completion
;; company` (nil in compat); dropped.

;;; BibTeX + RefTeX.
(leaf reftex
  :ensure nil
  :hook (LaTeX-mode . reftex-mode)
  :config
  ;; Get RefTeX working with BibLaTeX, see
  ;; http://tex.stackexchange.com/questions/31966/setting-up-reftex-with-biblatex-citation-commands/31992#31992.
  (setq reftex-cite-format
        '((?a . "\\autocite[]{%l}")
          (?b . "\\blockcquote[]{%l}{}")
          (?c . "\\cite[]{%l}")
          (?f . "\\footcite[]{%l}")
          (?n . "\\nocite{%l}")
          (?p . "\\parencite[]{%l}")
          (?s . "\\smartcite[]{%l}")
          (?t . "\\textcite[]{%l}"))
        reftex-plug-into-AUCTeX t
        reftex-toc-split-windows-fraction 0.3
        ;; This is needed when `reftex-cite-format' is set. See
        ;; https://superuser.com/a/1386206
        LaTeX-reftex-cite-format-auto-activate nil)
  (when (modulep! :editor evil)
    (add-hook 'reftex-mode-hook #'evil-normalize-keymaps))
  (general-def :keymaps 'reftex-mode-map :prefix doom-localleader-key
    ";" 'reftex-toc)
  (add-hook 'reftex-toc-mode-hook
            (lambda ()
              (reftex-toc-rescan)
              (define-key (current-local-map) "j" #'next-line)
              (define-key (current-local-map) "k" #'previous-line)
              (define-key (current-local-map) "q" #'kill-buffer-and-window)
              (define-key (current-local-map) (kbd "ESC") #'kill-buffer-and-window))))

;; Set up mode for bib files.
(after! bibtex
  (setq bibtex-dialect 'biblatex
        bibtex-align-at-equal-sign t
        bibtex-text-indentation 20)
  (define-key bibtex-mode-map (kbd "C-c \\") #'bibtex-fill-entry))


;;; lang/lean
;; lean-mode (+v3): not packaged in nixpkgs; dropped.
(leaf nael
  :ensure t
  :init
  (add-hook 'nael-mode-hook #'abbrev-mode)
  (with-eval-after-load 'org-src
    (add-to-list 'org-src-lang-modes '("lean" . nael)))
  (with-eval-after-load 'markdown-mode
    (add-to-list 'markdown-code-lang-modes '("lean" . nael-mode)))
  :config
  (sp-with-modes 'nael-mode
    (sp-local-pair "/-" "-/")
    (sp-local-pair "`" "`")
    (sp-local-pair "{" "}")
    (sp-local-pair "«" "»")
    (sp-local-pair "⟨" "⟩")
    (sp-local-pair "⟪" "⟫"))
  (general-def :keymaps 'nael-mode-map :prefix doom-localleader-key
    "a" #'nael-abbrev-help
    "b" #'project-build
    "e" #'eldoc-doc-buffer))
;; nael lsp wiring (`nael-prepare-lsp'/`lsp!') is gated on `+lsp` (nil in
;; compat); dropped.


;;; lang/lua
;; sp's default rules are obnoxious, so disable them
(provide 'smartparens-lua)

(defun +lua-common-config (mode)
  ;; doom also sets lookup/repl/company handlers here (set-*-handler!); those
  ;; have no vanilla equivalent in this config, so only the lsp hook survives.
  (when (modulep! +lsp)
    (add-hook (intern (format "%s-hook" mode)) #'lsp)))

(leaf lua-mode
  :ensure t
  :interpreter "\\<lua\\(?:jit\\)?"
  :init
  (setq lua-indent-level 2)  ; default is 3; madness!
  :config
  (+lua-common-config 'lua-mode))

;; lua-ts-mode / moonscript / fennel-mode: gated on flags (nil in compat);
;; dropped. Love2D project mode (`def-project-mode!') is a doom macro; dropped.


;;; lang/php
(defvar +php-default-docker-container "php-fpm"
  "The default docker container to run commands in.")

(defvar +php-default-docker-compose "docker-compose.yml"
  "Path to docker-compose file.")

(defvar +php-run-tests-in-docker nil
  "Whether or not to run tests in a docker environment")

;; DEPRECATED: Remove when projectile is replaced with project.el
(after! projectile
  (add-to-list 'projectile-project-root-files "composer.json"))

(defun +php-common-config (mode)
  (let ((mode-hook (intern (format "%s-hook" mode)))
        (mode-map (intern (format "%s-map" mode))))
    (sp-with-modes (ensure-list mode)
      (sp-local-pair "<?"    "?>" :post-handlers '(("| " "SPC" "=") ("||\n[i]" "RET") ("[d2]" "p")))
      (sp-local-pair "<?php" "?>" :post-handlers '(("| " "SPC") ("||\n[i]" "RET"))))
    (when (modulep! +lsp)
      (when (executable-find "php-language-server.php")
        (setq lsp-clients-php-server-command "php-language-server.php"))
      (add-hook mode-hook #'lsp))
    (general-def :keymaps mode-map
      :prefix (concat doom-localleader-key " t")
      "r" #'phpunit-current-project
      "a" #'phpunit-current-class
      "s" #'phpunit-current-test)))

(leaf php-mode
  :ensure t
  :config
  (+php-common-config 'php-mode)
  ;; Disable HTML compatibility in php-mode. `web-mode' has superior support for
  ;; php+html. Use the .phtml extension instead.
  (setq php-mode-template-compatibility nil))

;; php-ts-mode: gated on `+tree-sitter` (nil in compat); dropped.

(leaf php-refactor-mode
  :ensure t
  :hook (php-mode . php-refactor-mode)
  :config
  (general-def :keymaps 'php-refactor-mode-map
    :prefix (concat doom-localleader-key " r")
    "cv" #'php-refactor--convert-local-to-instance-variable
    "u"  #'php-refactor--optimize-use
    "xm" #'php-refactor--extract-method
    "rv" #'php-refactor--rename-local-variable))

;; hack-mode: gated on `+hack` (nil in compat); dropped.

(leaf composer
  :ensure t
  :init
  (defvar +php-common-mode-map (make-sparse-keymap))
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
  :config
  (setq composer-directory-to-managed-file (expand-file-name "composer/" user-emacs-directory))
  (with-eval-after-load 'php-mode
    (general-def :keymaps 'php-mode-map :prefix doom-localleader-key
      "c" +php-common-mode-map))
  (with-eval-after-load 'php-ts-mode
    (general-def :keymaps 'php-ts-mode-map :prefix doom-localleader-key
      "c" +php-common-mode-map)))

(leaf phpunit
  :ensure t
  :defer t)

(leaf psysh
  :ensure t
  :defer t)

;; `+php/open-repl' and the Laravel/composer project modes (`def-project-mode!')
;; are not portable; dropped.

;;; lang/qt
;; doom also registers an eglot client (`set-eglot-client!' mode '('qmlls')) and
;; an lsp hook per mode; only the lsp hook is portable here.
(defun +qt-common-config (mode)
  (when (modulep! +lsp)
    (add-hook (intern (format "%s-hook" mode)) #'lsp)))

(leaf qml-mode
  :ensure t
  :config
  (+qt-common-config 'qml-mode))

;; qml-ts-mode: gated on `+tree-sitter` (nil in compat); dropped.

(leaf qt-pro-mode
  :ensure t
  :mode "\\.pr[io]\\'")


;;; lang/ruby
;; DEPRECATED: Remove when projectile is replaced with project.el
(after! projectile
  (add-to-list 'projectile-project-root-files "Gemfile"))

(leaf ruby-mode  ; built-in
  ;; Other extensions are already registered in `auto-mode-alist' by `ruby-mode'
  :ensure nil
  :mode ("\\.\\(?:a?rb\\|aslsx\\)\\'"
         "/\\(?:Brew\\|Fast\\)file\\'")
  :interpreter "j?ruby\\(?:[0-9.]+\\)"
  :config
  (setq ruby-insert-encoding-magic-comment nil)
  ;; so class and module pairs work
  (add-hook 'ruby-mode-hook (lambda () (setq-local sp-max-pair-length 6)))
  (with-eval-after-load 'inf-ruby
    ;; Switch to inf-ruby from compile if a breakpoint is detected
    (add-hook 'compilation-filter-hook #'inf-ruby-auto-enter))
  (when (modulep! +lsp)
    (add-hook 'ruby-mode-hook #'lsp)))
;; ruby-toggle-block (bound to the opening-bracket keys) is not defined
;; anywhere in the ported sources or vanilla ruby-mode; dropped.

;; ruby-ts-mode: gated on `+tree-sitter` (nil in compat); dropped.

(leaf yard-mode
  :ensure t
  :hook (ruby-mode . yard-mode))

(leaf ruby-json-to-hash
  :ensure t
  :init
  (with-eval-after-load 'ruby-mode
    (general-def :keymaps 'ruby-mode-map :prefix doom-localleader-key
      "J" #'ruby-json-to-hash-parse-json
      "j" #'ruby-json-to-hash-toggle-let)))

;;; Package & Ruby version management
(leaf inf-ruby
  :ensure t
  :commands inf-ruby)

(leaf rake
  :ensure t
  :init
  (with-eval-after-load 'rake
    (setq rake-cache-file (doom-profile-cache-dir t "rake.cache")
          rake-completion-system 'default))
  (with-eval-after-load 'ruby-mode
    (general-def :keymaps 'ruby-mode-map
      :prefix (concat doom-localleader-key " k")
      "k" #'rake
      "r" #'rake-rerun
      "R" #'rake-regenerate-cache
      "f" #'rake-find-task)))

;; bundler: no nixpkgs emacs package; dropped.
;; chruby/rbenv/rvm: gated on +chruby/+rbenv (nil in compat); dropped.

;;; Testing frameworks
(leaf rspec-mode
  :ensure t
  :mode ("/\\.rspec\\'" . text-mode)
  :init
  (setq rspec-use-spring-when-possible nil)
  (when (modulep! :editor evil)
    (add-hook 'rspec-mode-hook #'evil-normalize-keymaps))
  :config
  (setq rspec-use-rvm (executable-find "rvm"))
  (general-def :keymaps '(rspec-verifiable-mode-map rspec-dired-mode-map rspec-mode-map)
    :prefix (concat doom-localleader-key " t")
    "a" #'rspec-verify-all
    "r" #'rspec-rerun)
  (general-def :keymaps '(rspec-verifiable-mode-map rspec-mode-map)
    :prefix (concat doom-localleader-key " t")
    "v" #'rspec-verify
    "c" #'rspec-verify-continue
    "l" #'rspec-run-last-failed
    "T" #'rspec-toggle-spec-and-target
    "t" #'rspec-toggle-spec-and-target-find-example)
  (general-def :keymaps 'rspec-verifiable-mode-map
    :prefix (concat doom-localleader-key " t")
    "f" #'rspec-verify-method
    "m" #'rspec-verify-matching)
  (general-def :keymaps 'rspec-mode-map
    :prefix (concat doom-localleader-key " t")
    "s" #'rspec-verify-single
    "e" #'rspec-toggle-example-pendingness)
  (general-def :keymaps 'rspec-dired-mode-map
    :prefix (concat doom-localleader-key " t")
    "v" #'rspec-dired-verify
    "s" #'rspec-dired-verify-single))

(leaf minitest
  :ensure t
  :config
  (when (modulep! :editor evil)
    (add-hook 'minitest-mode-hook #'evil-normalize-keymaps))
  (general-def :keymaps 'minitest-mode-map
    :prefix (concat doom-localleader-key " t")
    "r" #'minitest-rerun
    "a" #'minitest-verify-all
    "s" #'minitest-verify-single
    "v" #'minitest-verify))

;;; Rails integration
;; projectile-rails / rails-routes / rails-i18n / inflections: skipped per task
;; (+rails off).

;;; lang-extra-config.el ends here
(provide 'lang-extra-config)
