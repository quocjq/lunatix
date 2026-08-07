;;; early-init.el --- done before init.el  -*- lexical-binding: t; -*-
;;;
;;; Packages come from nix, never from package.el. The wrapper built by
;;; emacsWithPackagesFromUsePackage sets `use-package-ensure-function` to a
;;; no-op at startup; this just keeps package.el quiet before that runs.

(setq package-enable-at-startup nil)
(setq package-quickstart nil)
;;; early-init.el ends here
