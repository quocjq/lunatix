{ inputs, ... }:
{
  flake-file.inputs = {
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lnav = {
      url = "github:quocjq/lnav";
      flake = false;
    };
  };
  lix.doomacs = {
    provides.to-hosts.nixos = { pkgs, ... }: {
      # make magit works
      environment.systemPackages = with pkgs; [
        git
      ];
    };
    homeManager = { pkgs, config, ... }: {
      services.emacs.enable = true;
      nixpkgs.overlays = [
        inputs.emacs-overlay.overlays.default
        (import ./_eaf/overlay.nix)
      ];
      # EAF spawns Qt6 processes; without this env the subprocess
      # fails with "Could not find the Qt platform plugin 'xcb'".
      # See https://github.com/emacs-eaf/emacs-application-framework/wiki/NixOS
      home.sessionVariables = {
        QT_QPA_PLATFORM_PLUGIN_PATH = "${pkgs.qt6.qtbase}/lib/qt-6/plugins";
      };

      # declaratively link the repo config as ~/.emacs.d (out-of-store: edits
      # in the repo apply immediately, no rebuild).
      home.file.".emacs.d".source =
        config.lib.file.mkOutOfStoreSymlink "/home/lunixose/Proj/lunatix/emacs";

      services.emacs.package = pkgs.emacsWithPackagesFromUsePackage {
        package = pkgs.emacs-gtk;
        config =
          let
            initText = builtins.readFile "${inputs.self}/emacs/init.el";
            moduleFiles = pkgs.lib.filter (p: p != null) (
              map (f: if pkgs.lib.hasSuffix ".el" f then f else null)
                ((pkgs.lib.filesystem.listFilesRecursive "${inputs.self}/emacs/config")
                 ++ (pkgs.lib.filesystem.listFilesRecursive "${inputs.self}/emacs/framework"))
            );
          in
          pkgs.writeText "lunatix-modules.el" (
            builtins.concatStringsSep "\n" ([ initText ] ++ (map builtins.readFile moduleFiles))
          );
        defaultInitFile = false;
        alwaysEnsure = true;
        extraEmacsPackages =
          epkgs:
          let
            apps = import ./_eaf/apps.nix;
            eaf = import ./_eaf/scope.nix { inherit inputs pkgs epkgs; };
            lnav = (import ./_lnav/scope.nix { inherit inputs pkgs epkgs; }).lnav;
          in
          [
            epkgs.eglot
            epkgs.astro-ts-mode
            epkgs.treesit-grammars.with-all-grammars
            (eaf.withApplications (apps eaf))
            lnav
          ];
      };

      home.packages = [
        # `services.emacs.package` runs the daemon; also expose the binary on
        # PATH so `emacs` works in the shell.
        config.services.emacs.package
      ]
      ++ (with pkgs; [
        (pkgs.aspellWithDicts (dicts: [
          dicts.en
          dicts.en-computers
        ]))
        languagetool
        nerd-fonts.symbols-only
        nerd-fonts.jetbrains-mono
        fd
        ripgrep
        nodejs
        xdotool
        ddate
        shfmt
        shellcheck
        sqlite
        # :emacs dired +dirvish (for file previews)
        ffmpegthumbnailer
        mediainfo
        vips
        editorconfig-core-c
        # lsp + compiler + fmt
        gcc
        gnumake
        ccls
        zig
        zls
        graphviz
        # Go
        go-grip
        # Markdown
        marksman # markdown language server
        pandoc
        multimarkdown
        gopls # go language server
        mupdf # mutool for pdf-tools rendering
        dockfmt
        html-tidy
        universal-ctags

        # TeX (required by latex-preview for dvisvgm-backed inline rendering)
        texliveFull
        jdt-language-server
        bash-language-server
        yaml-language-server
        # python
        black
        python313Packages.pyflakes
        isort
        python312Packages.pytest
        pyenv
        pyright
        python3
        pipenv

        # Nix
        nil # nix language server
        nixd
        nixfmt
        nixfmt-tree

        # lisp
        sbcl

        # Rust
        cargo
        cargo-watch
        cargo-expand
        cargo-edit
        cargo-audit
        cargo-flamegraph
        bacon
        rustc
        rustfmt
        clippy
        rust-analyzer

        # JS/TS/Vue (web-mode + lsp-mode; tsserver covers vue in web-mode)
        typescript-language-server # LSP: js/ts/tsx, and vue via web-mode
        eslint
        astro-language-server # LSP: astro-ls for .astro (astro-ts-mode + lsp-astro)
      ]);
    };
  };
}
