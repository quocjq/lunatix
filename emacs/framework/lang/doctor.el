;;; lang/doctor.el --- doom doctor-style health checks for :lang  -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Loaded only by `lunaris-doctor`. Each form gates on `(modulep! ...)' and
;;; reports via `ok!'/`warn!'/`error!'.
;;; Safe to load outside lunaris (e.g. nix's package scan evaluates the
;;; concatenated config without the framework loaded): no-op shims.
(unless (fboundp 'modulep!)
  (defmacro modulep! (&rest _) t)
  (defmacro ok! (&rest _) nil)
  (defmacro warn! (&rest _) nil)
  (defmacro error! (&rest _) nil))

(when (modulep! :lang python)
  (ok! "python module enabled")
  (unless (executable-find "python3")
    (error! "python3 not found; python LSP/run will fail"))
  (unless (executable-find "pyright")
    (warn! "pyright not found; python LSP unavailable"))
  (unless (executable-find "black")
    (warn! "black not found; python formatting unavailable")))

(when (modulep! :lang rust)
  (ok! "rust module enabled")
  (unless (executable-find "rust-analyzer")
    (error! "rust-analyzer not found; rust LSP unavailable"))
  (unless (executable-find "cargo")
    (warn! "cargo not found; cargo commands unavailable")))

(when (modulep! :lang go)
  (ok! "go module enabled")
  (unless (executable-find "gopls")
    (warn! "gopls not found; go LSP unavailable")))

(when (modulep! :lang cc)
  (ok! "cc module enabled")
  (unless (executable-find "ccls")
    (warn! "ccls not found; c/c++ LSP unavailable"))
  (unless (executable-find "gcc")
    (warn! "gcc not found; compile unavailable")))

(when (modulep! :lang sh)
  (ok! "sh module enabled")
  (unless (executable-find "shellcheck")
    (warn! "shellcheck not found; shell linting unavailable"))
  (unless (executable-find "shfmt")
    (warn! "shfmt not found; shell formatting unavailable")))

(when (modulep! :lang nix)
  (ok! "nix module enabled")
  (unless (executable-find "nix")
    (error! "nix not found; nix module unusable"))
  (unless (executable-find "nil")
    (warn! "nil not found; nix LSP unavailable")))

(when (modulep! :lang markdown)
  (ok! "markdown module enabled")
  (unless (executable-find "pandoc")
    (warn! "pandoc not found; markdown export unavailable"))
  (unless (executable-find "marksman")
    (warn! "marksman not found; markdown LSP unavailable")))

(when (modulep! :lang org)
  (ok! "org module enabled")
  (unless (executable-find "pandoc")
    (warn! "pandoc not found; org export to non-org formats unavailable")))

(when (modulep! :lang latex)
  (ok! "latex module enabled")
  (unless (executable-find "latexmk")
    (error! "latexmk not found; latex compilation unavailable"))
  (unless (executable-find "dvisvgm")
    (warn! "dvisvgm not found; inline latex preview unavailable")))

(when (modulep! :lang web)
  (ok! "web module enabled")
  (unless (executable-find "node")
    (warn! "node not found; web/JS tooling unavailable")))

(when (modulep! :lang lua)
  (ok! "lua module enabled")
  (unless (executable-find "lua")
    (warn! "lua not found; lua-mode REPL unavailable")))

(when (modulep! :lang java)
  (ok! "java module enabled")
  (unless (executable-find "jdtls")
    (warn! "jdtls not found; java LSP unavailable")))

(when (modulep! :lang lean)
  (warn! "lean module is not enabled in the manifest (file exists but off)"))
