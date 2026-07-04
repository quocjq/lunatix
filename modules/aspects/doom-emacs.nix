{ inputs, ... }:
{
  flake-file.inputs.nix-doom-emacs-unstraightened = {
    url = "github:marienz/nix-doom-emacs-unstraightened";
    inputs.nixpkgs.follows = "";
  };

  den.aspects.doom-emacs = {
    homeManager = { pkgs, ... }: {
      imports = [ inputs.nix-doom-emacs-unstraightened.homeModule ];

      programs.doom-emacs = {
        enable = true;
        doomDir = ../../doomdir;
        tangleArgs = "--all config.org";
        extraPackages =
          epkgs: with epkgs; [
            eglot
            nix-ts-mode
            vterm
            treesit-grammars.with-all-grammars
          ];
      };
      home.packages = with pkgs; [
        (pkgs.aspellWithDicts (dicts: [
          dicts.en
          dicts.en-computers
        ]))
        languagetool
        nerd-fonts.symbols-only
        twemoji-color-font
        emacs-lsp-booster
        findutils
        coreutils
        fd
        ripgrep
        ddate
        shfmt
        shellcheck
        nodejs_24
        python3
        pipenv
        sqlite
        duckdb
        wordnet
        # :emacs dired +dirvish (for file previews)
        ffmpegthumbnailer
        mediainfo
        vips

        editorconfig-core-c

        # clang # conflits with gcc, TODO: decide which one to set here
        gcc
        gnumake
        ccls
        zig
        zls
        graphviz
        tuntox # for (collab +tunnel)
        pyright
        go-grip
        marksman # markdown language server
        hugo
        dockfmt
        html-tidy
        semgrep
        ripgrep-all
        universal-ctags
        jdk
        jdt-language-server
        bash-language-server
        yaml-language-server
        haskell-language-server
        haskellPackages.hoogle
        cabal-install
        black
        python313Packages.pyflakes
        isort
        python312Packages.pytest
        pyenv
        nil # nix language server
        nixd
        nixfmt
        nixfmt-tree
        deadnix
        nixpkgs-review
        nix-output-monitor
        nix-fast-build
      ];
    };
  };
}
