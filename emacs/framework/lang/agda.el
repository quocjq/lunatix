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
)
;;; lang/agda.el ends here