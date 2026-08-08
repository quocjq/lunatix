;;; ui/hl-todo.el --- doom ui/hl-todo port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/ui/hl-todo.
;;; Code:

;;; :ui hl-todo
(leaf hl-todo
  :ensure t
  :defer t
  :config
  (setq hl-todo-highlight-punctuation ":"
        ;; Don't highlight todo keywords in text-mode derivatives unless in
        ;; comments (e.g. data formats like yaml, json, etc).
        hl-todo-text-modes nil
        hl-todo-keyword-faces
        '(;; For reminders to change or add something at a later date.
          ("TODO" warning bold)
          ;; For code (or code paths) that are broken, unimplemented, or slow,
          ;; and may become bigger problems later.
          ("FIXME" error bold)
          ;; For code that needs to be revisited later, either to upstream it,
          ;; improve it, or address non-critical issues.
          ("REVIEW" font-lock-keyword-face bold)
          ;; For code smells where questionable practices are used intentionally
          ;; and is likely to break in a future update.
          ("HACK" font-lock-constant-face bold)
          ;; For sections of code that just gotta go, and will be gone soon.
          ("DEPRECATED" font-lock-doc-face bold)
          ;; Extra keywords commonly found in the wild, whose meaning may vary
          ;; from project to project.
          ("BUG" error bold)
          ("XXX" font-lock-constant-face bold)
          ("NOTE" success bold)))

  (defadvice! +hl-todo-clamp-font-lock-fontify-region-a (fn &rest args)
    ;; Fix an `args-out-of-range' error in some modes.
    :around #'hl-todo-mode
    (cl-letf (((symbol-function #'font-lock-fontify-region)
               (lambda (beg end &optional loudly)
                 (funcall (symbol-function #'font-lock-fontify-region)
                          (max beg 1) end loudly))))
      (apply fn args)))

  ;; APROX: doom hooked `luna-first-buffer' (a no-op hook in the compat layer);
  ;; enable the global mode at startup instead.
  (global-hl-todo-mode +1))

;; Use a more primitive todo-keyword detection method in major modes that
;; don't use/have a valid syntax table entry for comments.
(defun +hl-todo--use-face-detection-h ()
  "Use a different, more primitive method of locating todo keywords."
  (set (make-local-variable 'hl-todo-keywords)
       '(((lambda (limit)
            (let (case-fold-search)
              (and (re-search-forward hl-todo-regexp limit t)
                   (memq 'font-lock-comment-face
                         (ensure-list (get-text-property (point) 'face))))))
          (1 (hl-todo-get-face) t t))))
  (when hl-todo-mode
    (hl-todo-mode -1)
    (hl-todo-mode +1)))

(add-hook 'pug-mode-hook #'+hl-todo--use-face-detection-h)
(add-hook 'haml-mode-hook #'+hl-todo--use-face-detection-h)

;;; ui/hl-todo.el ends here
