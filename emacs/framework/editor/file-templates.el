;;; editor/file-templates.el --- doom editor/file-templates port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/editor/file-templates.
;;; Code:

;;; File templates (doom editor/file-templates, simplified)
(leaf autoinsert
  :ensure nil
  :defer t
  :config
  (auto-insert-mode 1)
  (setq auto-insert-query nil)
  (setq auto-insert-alist
        (append
         '((("\\.el\\'" . "Emacs Lisp header") nil
            ";;; " (file-name-nondirectory buffer-file-name) " --- "
            (or (ignore-errors (upcase (file-name-base buffer-file-name))) "")
            "  -*- lexical-binding: t; -*-" "\n\n"
            ";;; " (file-name-nondirectory buffer-file-name) " ends here" "\n"))
         auto-insert-alist)))

;;; Undo (doom emacs/undo) moved to framework/emacs/undo.el

;;; editor/file-templates.el ends here
