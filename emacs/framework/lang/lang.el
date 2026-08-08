;;; lang/lang.el --- doom :lang group file (shared shims)  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/lang.
;;; Code:

;;; Module files in this dir are gated by `(modulep! :lang <module>)' in the
;;; manifest; this group file always loads first.

;;; lang-config.el --- doom :lang modules, ported  -*- lexical-binding: t; -*-

;; Ported from doom-modules/modules/lang/{emacs-lisp,org,python,rust,go,cc,
;; nix,sh,markdown,json,yaml,javascript,web}.  Doom-only macros with no compat
;; layer (set-docsets!/set-lookup-handlers!/set-repl-handler!/set-ligatures!/...)
;; are dropped.  Hooks are plain `add-hook' and keybindings use `general', since
;; the compat `map!'/`add-hook!' forms don't survive doom's calling conventions
;; (`:localleader', nested `(:prefix ...)' groups, quoted hook symbols).

;;; Shims for doom-core macros the copied helpers rely on.
(defmacro dlet (bindings &rest body)
  "Vanilla stand-in for doom's `dlet' (dynamic let)."
  (declare (indent 1))
  `(let ,bindings ,@body))

(defmacro quiet! (&rest body)
  "Vanilla stand-in for doom's `quiet!'."
  (declare (indent 0))
  `(let ((inhibit-message t)) (message nil) ,@body))

;;; lang/lang.el ends here