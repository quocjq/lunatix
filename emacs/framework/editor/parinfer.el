;;; editor/parinfer.el --- doom editor/parinfer port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/editor/parinfer.
;;; Code:

;;; Parinfer (doom editor/parinfer)
(leaf parinfer-rust-mode
  :ensure t
  :when (bound-and-true-p module-file-suffix)
  :hook ((emacs-lisp-mode
          clojure-mode
          scheme-mode
          lisp-mode) . parinfer-rust-mode)
  :init
  (setq parinfer-rust-disable-troublesome-modes t)
  :config
  ;; auto-approve indentation rewrites — no y-or-n-p prompt on every lisp buffer
  (defun parinfer-rust--check-for-indentation (&rest _)
    (when (parinfer-rust--execute-change-buffer-p "paren")
      (let ((parinfer-rust--mode "paren"))
        (parinfer-rust--execute)))))

;;; editor/parinfer.el ends here
