;;; lang/lua.el --- doom lang/lua port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/lua.
;;; Code:

;;; lang/lua

(defun +lua-common-config (mode)
  ;; doom also sets lookup/repl/company handlers here (set-*-handler!); those
  ;; have no vanilla equivalent in this config, so only the lsp hook survives.
  (when (modulep! +lsp)
    (add-hook (intern (format "%s-hook" mode)) #'lsp)))

(leaf lua-mode
  :ensure t
  :interpreter "\\<lua\\(?:jit\\)?"
  :init
  (setq lua-indent-level 2)  ; default is 3; madness!
  :config
  (+lua-common-config 'lua-mode))

;; lua-ts-mode / moonscript / fennel-mode: gated on flags (nil in compat);
;; dropped. Love2D project mode (`def-project-mode!') is a doom macro; dropped.

;;; lang/lua.el ends here