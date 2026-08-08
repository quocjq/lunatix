;;; lang/agda.el --- doom lang/agda port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/agda.
;;; Code:

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

;;; lang/agda.el ends here