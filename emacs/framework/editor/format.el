;;; editor/format.el --- doom editor/format port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/editor/format.
;;; Code:

;;; Format (doom editor/format +onsave)
(defcustom +format-on-save-disabled-modes
  '(sql-mode tex-mode latex-mode LaTeX-mode org-msg-edit-mode)
  "Modes in which not to reformat on save.")

(leaf apheleia
  :ensure t
  :defer t
  :config
  (when (boundp 'apheleia-inhibit-functions)
    (add-hook 'apheleia-inhibit-functions
              (lambda ()
                (or (eq major-mode 'fundamental-mode)
                    (string-blank-p (buffer-name))
                    (eq +format-on-save-disabled-modes t)
                    (memq major-mode +format-on-save-disabled-modes)))))
  (add-hook 'prog-mode-hook #'apheleia-mode)
  (when (boundp 'apheleia-mode-map)
    (define-key apheleia-mode-map [remap basic-save-buffer] #'+format/save-buffer))
  (add-to-list 'apheleia-mode-alist '(sh-mode . shfmt)))

(defun +format/save-buffer ()
  "Format buffer then save."
  (interactive)
  (when apheleia-mode
    (apheleia-format-buffer))
  (save-buffer))

;;; editor/format.el ends here
