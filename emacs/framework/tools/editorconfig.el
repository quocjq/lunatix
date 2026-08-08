;;; tools/editorconfig.el --- doom tools/editorconfig port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/tools/editorconfig. Uses the lunatix-doom compat layer.
;;; Code:

;;; tools/editorconfig

(leaf editorconfig
  :ensure t
  :defer t
  :config
  (editorconfig-mode 1)
  ;; The elisp implementation is the default (rather than the external
  ;; editorconfig binary).
  (setq editorconfig-get-properties-function #'editorconfig-get-properties)

  (when (modulep! :editor whitespace +trim)
    (setq editorconfig-trim-whitespaces-mode 'ws-butler-mode))

  ;; Archives don't need editorconfig settings (office formats are zipped XML).
  (add-to-list 'editorconfig-exclude-regexps
               "\\.\\(zip\\|\\(doc\\|xls\\|ppt\\)x\\)\\'")

  (defun +editorconfig-disable-indent-detection-h (props)
    "Inhibit `dtrt-indent' if an explicit indent_style and indent_size is
specified by editorconfig."
    (when (and (modulep! :editor whitespace +guess)
               (boundp '+whitespace-guess-inhibit)
               (not +whitespace-guess-inhibit)
               (or (gethash 'indent_style props)
                   (gethash 'indent_size props)))
      (setq +whitespace-guess-inhibit 'editorconfig)))
  (defun +editorconfig-unset-tab-width-in-org-mode-h (props)
    "A tab-width != 8 is an error state in org-mode, so prevent changing it."
    (when (and (gethash 'indent_size props)
               (derived-mode-p 'org-mode))
      (unless (fboundp 'org--set-tab-width)
        (setq tab-width 8))))
  (add-hook 'editorconfig-after-apply-functions #'+editorconfig-disable-indent-detection-h)
  (add-hook 'editorconfig-after-apply-functions #'+editorconfig-unset-tab-width-in-org-mode-h))

;;

;;; tools/editorconfig.el ends here
