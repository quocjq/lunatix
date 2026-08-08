;;; lang/data.el --- doom lang/data port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/lang/data.
;;; Code:

;;; lang/data
;; yaml/json/nix live in lang-config.el (other submodules); lang/data only
;; contributes nxml-mode (xml/xsd/plist/rss) + csv-mode.

(leaf nxml-mode
  :ensure nil
  :defer t
  :mode ("\\.p\\(?:list\\|om\\)\\'"   ; plist, pom
         "\\.xs\\(?:d\\|lt\\)\\'"     ; xslt, xsd
         "\\.rss\\'")
  :config
  (setq nxml-slash-auto-complete-flag t
        nxml-auto-insert-xml-declaration-flag t)
  (lnav-local-pair '(nxml-mode) "<" ">"))

(leaf csv-mode
  :ensure t
  :defer t)

;;; lang/data.el ends here