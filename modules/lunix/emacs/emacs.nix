{ inputs, ... }:
{
  flake-file.inputs = {
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  lix.doomacs = {
    provides.to-hosts.nixos = { pkgs, ... }: {
      # make magit works
      environment.systemPackages = with pkgs; [
        git
      ];
    };
    homeManager = { pkgs, ... }: {
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

      services.emacs.package = pkgs.emacsWithPackagesFromUsePackage {
        package = pkgs.emacs-gtk;
        config =
          let
            initText = builtins.readFile ../../../emacs/init.el;
            moduleFiles = pkgs.lib.filter (p: p != null) (
              map (f: if pkgs.lib.hasSuffix ".el" f then f else null)
                (pkgs.lib.filesystem.listFilesRecursive ../../../emacs/modules)
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
          in
          [
            epkgs.eglot
            epkgs.treesit-grammars.with-all-grammars
            (eaf.withApplications (apps eaf))
          ];
      };

      home.packages = with pkgs; [
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
      ];
    };
  };
}
