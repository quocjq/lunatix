;;; editor/whitespace.el --- doom editor/whitespace port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/editor/whitespace.
;;; Code:

;;; Whitespace (doom editor/whitespace +guess +trim)
(defvar +whitespace-guess-excluded-modes
  '(pascal-mode so-long-mode emacs-lisp-mode coq-mode org-mode)
  "Modes where indentation shouldn't be auto-detected.")

(defvar +whitespace-guess-in-projects nil
  "If non-nil, guess indentation in project files too.")

(leaf whitespace
  :ensure nil
  :defer t
  :config
  (setq whitespace-line-column nil
        whitespace-style
        '(face indentation tabs tab-mark spaces space-mark newline newline-mark trailing)))

(leaf ws-butler
  :ensure t
  :hook (prog-mode . ws-butler-mode))

(leaf dtrt-indent
  :ensure t
  :hook ((change-major-mode-after-body read-only-mode) . +whitespace-guess-indentation-h)
  :config
  (setq dtrt-indent-run-after-smie t
        dtrt-indent-max-lines 2000))

(defun +whitespace-guess-indentation-h ()
  (unless (or (not after-init-time)
              (eq major-mode 'fundamental-mode)
              (member (substring (buffer-name) 0 1) '(" " "*"))
              (apply #'derived-mode-p +whitespace-guess-excluded-modes)
              buffer-read-only
              (and (not +whitespace-guess-in-projects)
                   (luna-project-root)))
    (dtrt-indent-mode +1)))

;;; editor/whitespace.el ends here
