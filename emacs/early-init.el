;;; early-init.el --- done before init.el  -*- lexical-binding: t; -*-
;;;
;;; Packages come from nix, never from package.el. The wrapper built by
;;; emacsWithPackagesFromUsePackage sets `use-package-ensure-function' to a
;;; no-op at startup; this just keeps package.el quiet before that runs.

(setq package-enable-at-startup nil)
(setq package-quickstart nil)

;; nix precompiles every package to .eln; our own cache .elc don't need it.
;; Background native-comp of them grinds this laptop's compiler to a near-hang
;; (spawns workers that churn for minutes). Skip it.
(setq native-comp-deferred-compilation nil)

;; quiet startup: no "Compiling file ..." spam in *Messages*/*Async log*
(setq byte-compile-verbose nil)

;; silence native-comp/byte-comp warning spam (package cross-ref noise)
(setq native-comp-async-report-warnings-errors nil
      byte-compile-warnings '(not free-vars unresolved callargs redefine obsolete))

;; native-comp eln cache → XDG cache (must be set before comp.el initializes)
(let ((dir (expand-file-name
            "lunatix-emacs/eln"
            (or (getenv "XDG_CACHE_HOME")
                (expand-file-name ".cache" (or (getenv "HOME") "/tmp"))))))
  (make-directory dir t)
  (setq native-comp-eln-load-path (list dir)))
;;; early-init.el ends here
