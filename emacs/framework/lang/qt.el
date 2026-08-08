;;; lang/qt.el --- doom lang/qt port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/qt.
;;; Code:

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

;;; lang/qt.el ends here