;;; tools/doctor.el --- doom doctor-style health checks for :tools  -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Loaded only by `lunaris-doctor`. Each form gates on `(modulep! ...)' and
;;; reports via `ok!'/`warn!'/`error!'.
;;; Safe to load outside lunaris (e.g. nix's package scan evaluates the
;;; concatenated config without the framework loaded): no-op shims.
(unless (fboundp 'modulep!)
  (defmacro modulep! (&rest _) t)
  (defmacro ok! (&rest _) nil)
  (defmacro warn! (&rest _) nil)
  (defmacro error! (&rest _) nil))

(when (modulep! :tools docker)
  (ok! "docker module enabled")
  (unless (executable-find "docker")
    (error! "docker not found; docker module unusable")))

(when (modulep! :tools editorconfig)
  (ok! "editorconfig module enabled")
  (unless (executable-find "editorconfig")
    (warn! "editorconfig binary not found; file-style application limited")))

(when (modulep! :tools lookup)
  (ok! "lookup module enabled")
  (unless (executable-find "ripgrep")
    (warn! "ripgrep not found; project search falls back to grep")))

(when (modulep! :tools lsp)
  (ok! "lsp module enabled"))

(when (modulep! :tools magit)
  (ok! "magit module enabled")
  (unless (executable-find "git")
    (error! "git not found; magit unusable")))

(when (modulep! :tools pdf)
  (ok! "pdf module enabled")
  (unless (executable-find "mutool")
    (warn! "mutool (mupdf-tools) not found; pdf-tools rendering may fail")))

(when (modulep! :tools tree-sitter)
  (ok! "tree-sitter module enabled")
  (unless (treesit-available-p)
    (error! "treesit unavailable; :tools tree-sitter module unusable")))

(when (modulep! :tools upload)
  (ok! "upload module enabled")
  (unless (executable-find "scp")
    (warn! "scp not found; upload module needs it")))
