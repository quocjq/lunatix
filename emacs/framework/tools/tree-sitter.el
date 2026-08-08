;;; tools/tree-sitter.el --- doom tools/tree-sitter port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/tools/tree-sitter. Uses the lunatix-doom compat layer.
;;; Code:

;; source alist (pins chosen for the ABI shipped with Emacs 30).
(leaf treesit
  :ensure nil
  :when (treesit-available-p)
  :defer t
  :config
  (setq +tree-sitter--commit-field?
        (eq (cdr (func-arity
                  (advice--cd*r
                   (advice--symbol-function 'treesit--install-language-grammar-1))))
            'many))

  ;; Keep $EMACSDIR clean by installing grammars to a central location.
  (let ((data-dir (luna-profile-data-dir t "tree-sitter")))
    (add-to-list 'treesit-extra-load-path data-dir)
    ;; Treesit's API saw major changes in 30.x.  (`treesit--build-grammar' only
    ;; exists in 31+, so only `treesit-install-language-grammar' is advised.)
    (defadvice! +tree-sitter--install-grammar-to-local-dir-a (fn lang &optional out-dir &rest args)
      :around #'treesit-install-language-grammar
      (apply fn lang (or out-dir data-dir) args)))

  (cl-defun +tree-sitter-source (name &key url rev source-dir cc cpp commit)
    (cons name
          (append (list url rev source-dir cc cpp)
                  (if +tree-sitter--commit-field?
                      (list commit)))))

  (dolist (map `(;; Module-less (or major-mode-less) grammars
                 (awk :url "https://github.com/Beaglefoot/tree-sitter-awk")
                 (bibtex :url "https://github.com/latex-lsp/tree-sitter-bibtex")
                 (blueprint :url "https://github.com/huanie/tree-sitter-blueprint")
                 (commonlisp :url "https://github.com/tree-sitter-grammars/tree-sitter-commonlisp")
                 (latex :url "https://github.com/latex-lsp/tree-sitter-latex"
                        :commit "a6c812704b3d3e1541b0853aa0d6d561301320e1")
                 (make :url "https://github.com/tree-sitter-grammars/tree-sitter-make")
                 (nu :url "https://github.com/nushell/tree-sitter-nu")
                 (org :url "https://github.com/milisims/tree-sitter-org")
                 (perl :url "https://github.com/ganezdragon/tree-sitter-perl")
                 (proto :url "https://github.com/mitchellh/tree-sitter-proto")
                 (r :url "https://github.com/r-lib/tree-sitter-r")
                 (sql :url "https://github.com/DerekStride/tree-sitter-sql" :rev "gh-pages")
                 (surface :url "https://github.com/connorlay/tree-sitter-surface")
                 (toml :url "https://github.com/tree-sitter-grammars/tree-sitter-toml"
                       :rev "v0.7.0")
                 (typst :url "https://github.com/uben0/tree-sitter-typst"
                        :rev "master"
                        :source-dir "src")
                 (systemverilog :url "https://github.com/gmlarumbe/tree-sitter-systemverilog")
                 (vhdl :url "https://github.com/alemuller/tree-sitter-vhdl")
                 (vue :url "https://github.com/tree-sitter-grammars/tree-sitter-vue")
                 (wast :url "https://github.com/wasm-lsp/tree-sitter-wasm"
                       :source-dir "wast/src")
                 (wat :url "https://github.com/wasm-lsp/tree-sitter-wasm"
                      :source-dir "wat/src")
                 (wgsl :url "https://github.com/mehmetoguzderin/tree-sitter-wgsl")

                 ;; Grammars with modules
                 (ada :url "https://github.com/briot/tree-sitter-ada")
                 (c :url "https://github.com/tree-sitter/tree-sitter-c"
                    :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.6" "v0.24.1"))
                 (cpp :url "https://github.com/tree-sitter/tree-sitter-cpp"
                      :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.4")
                      :commit "80f5bd82d3b4a1acf07f34a569d88a4a29f74c42")
                 (cmake :url "https://github.com/uyha/tree-sitter-cmake")
                 (c-sharp :url "https://github.com/tree-sitter/tree-sitter-c-sharp"
                          :rev ,(if (< (treesit-library-abi-version) 15) "v0.20.0" "v0.23.1")
                          :commit "3431444351c871dffb32654f1299a00019280f2f")
                 (clojure :url "https://github.com/sogaiu/tree-sitter-clojure")
                 (cuda :url "https://github.com/tree-sitter-grammars/tree-sitter-cuda")
                 (css :url "https://github.com/tree-sitter/tree-sitter-css"
                      :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.0" "v0.23.2"))
                 (dart :url "https://github.com/ast-grep/tree-sitter-dart")
                 (dockerfile :url "https://github.com/camdencheek/tree-sitter-dockerfile"
                             :commit "087daa20438a6cc01fa5e6fe6906d77c869d19fe")
                 (doxygen :url "https://github.com/tree-sitter-grammars/tree-sitter-doxygen"
                          :commit "1e28054cb5be80d5febac082706225e42eff14e6")
                 (elixir :url "https://github.com/elixir-lang/tree-sitter-elixir"
                         :commit "d24cecee673c4c770f797bac6f87ae4b6d7ddec5")
                 (erlang :url "https://github.com/WhatsApp/tree-sitter-erlang")
                 (fsharp :url "https://github.com/ionide/tree-sitter-fsharp"
                         :rev ,(if (< (treesit-library-abi-version) 15) "v0.1.0" "v0.2.0")
                         :commit "594c500ecace8618db32dd1144307897277db067")
                 (gdscript :url "https://github.com/PrestonKnopp/tree-sitter-gdscript.git"
                           :rev ,(if (< (treesit-library-abi-version) 15) "v5.0.1" "v6.1.0"))
                 (glsl :url "https://github.com/tree-sitter-grammars/tree-sitter-glsl")
                 (graphql :url "https://github.com/bkegley/tree-sitter-graphql")
                 (go :url "https://github.com/tree-sitter/tree-sitter-go"
                     :rev ,(if (< (treesit-library-abi-version) 15)
                               (if (< emacs-major-version 30) "v0.20.0" "v0.23.4")
                             "v0.25.0"))
                 (gomod :url "https://github.com/camdencheek/tree-sitter-go-mod"
                        :commit "3b01edce2b9ea6766ca19328d1850e456fde3103")
                 (gowork :url "https://github.com/omertuc/tree-sitter-go-work"
                         :commit "949a8a470559543857a62102c84700d291fc984c")
                 (gpr :url "https://github.com/brownts/tree-sitter-gpr")
                 (haskell :url "https://github.com/tree-sitter/tree-sitter-haskell")
                 (heex :url "https://github.com/phoenixframework/tree-sitter-heex"
                       :commit "b5a7cb5f74dc695a9ff5f04919f872ebc7a895e9")
                 (html :url "https://github.com/tree-sitter/tree-sitter-html"
                       :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.0" "v0.23.2"))
                 (janet-simple :url "https://github.com/sogaiu/tree-sitter-janet-simple"
                               :cc ,(if (featurep :system 'windows) "gcc.exe"))
                 (java :url "https://github.com/tree-sitter/tree-sitter-java"
                       :commit "94703d5a6bed02b98e438d7cad1136c01a60ba2c")
                 (javascript :url "https://github.com/tree-sitter/tree-sitter-javascript"
                             :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.0" "v0.25.0"))
                 (jsdoc :url "https://github.com/tree-sitter/tree-sitter-jsdoc"
                        :rev "v0.23.2")
                 (json :url "https://github.com/tree-sitter/tree-sitter-json"
                       :commit "4d770d31f732d50d3ec373865822fbe659e47c75")
                 (julia :url "https://github.com/tree-sitter/tree-sitter-julia")
                 (kotlin :url "https://github.com/fwcd/tree-sitter-kotlin")
                 (lua :url "https://github.com/tree-sitter-grammars/tree-sitter-lua"
                      :rev ,(if (< (treesit-library-abi-version) 15) "v0.3.0")
                      :commit "db16e76558122e834ee214c8dc755b4a3edc82a9")
                 (markdown :url "https://github.com/tree-sitter-grammars/tree-sitter-markdown"
                           :rev ,(if (< (treesit-library-abi-version) 15) "v0.4.1" "v0.5.3")
                           :source-dir "tree-sitter-markdown/src")
                 (markdown-inline :url "https://github.com/tree-sitter-grammars/tree-sitter-markdown"
                                  :rev ,(if (< (treesit-library-abi-version) 15) "v0.4.1" "v0.5.3")
                                  :source-dir "tree-sitter-markdown-inline/src")
                 (nix :url "https://github.com/nix-community/tree-sitter-nix")
                 (odin :url "https://github.com/tree-sitter-grammars/tree-sitter-odin"
                       :rev "v1.3.0")
                 (openscad :url "https://github.com/openscad/tree-sitter-openscad"
                           :rev "v0.7.1")
                 (php :url "https://github.com/tree-sitter/tree-sitter-php"
                      :rev "v0.23.11"
                      :commit ,(if (and (treesit-available-p)
                                        (< (treesit-library-abi-version) 15))
                                   "f7cf7348737d8cff1b13407a0bfedce02ee7b046"
                                 "5b5627faaa290d89eb3d01b9bf47c3bb9e797dea")
                      :source-dir "php/src")
                 (phpdoc :url "https://github.com/claytonrcarter/tree-sitter-phpdoc"
                         :commit "03bb10330704b0b371b044e937d5cc7cd40b4999")
                 (python :url "https://github.com/tree-sitter/tree-sitter-python"
                         :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.6" "v0.25.0"))
                 (ruby :url "https://github.com/tree-sitter/tree-sitter-ruby"
                       :commit "71bd32fb7607035768799732addba884a37a6210")
                 (rust :url "https://github.com/tree-sitter/tree-sitter-rust"
                       :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.2" "v0.24.2"))
                 (scala :url "https://github.com/tree-sitter/tree-sitter-scala")
                 (sml :url "https://github.com/MatthewFluet/tree-sitter-sml"
                      :rev ,(if (< (treesit-library-abi-version) 15) "v0.23.0")
                      :commit "fd4b4955bb998262840ab8119885b3edf20ea75a")
                 (swift :url "https://github.com/alex-pinkus/tree-sitter-swift"
                        :rev "0.7.1-with-generated-files")
                 (typescript :url "https://github.com/tree-sitter/tree-sitter-typescript"
                             :commit "8e13e1db35b941fc57f2bd2dd4628180448c17d5"
                             :source-dir "typescript/src")
                 (tsx :url "https://github.com/tree-sitter/tree-sitter-typescript"
                      :commit "8e13e1db35b941fc57f2bd2dd4628180448c17d5"
                      :source-dir "tsx/src")
                 (qmljs :url "https://github.com/yuja/tree-sitter-qmljs")
                 (yaml :url "https://github.com/tree-sitter-grammars/tree-sitter-yaml"
                       :rev ,(if (< (treesit-library-abi-version) 15) "v0.7.2" "v0.7.0"))
                 (zig :url "https://github.com/tree-sitter-grammars/tree-sitter-zig")))
    (cl-pushnew (apply #'+tree-sitter-source map)
                treesit-language-source-alist
                :key #'car
                :test #'eq)))

;; Old tree-sitter.el ecosystem removed — redundant with builtin treesit
;; (see lang/lang-extra.el remap). set-tree-sitter! helpers above remain
;; available for code that references them.

;;
;;; tools/upload

;;; tools/tree-sitter.el ends here
