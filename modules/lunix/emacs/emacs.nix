{ inputs, ... }:
{
  flake-file.inputs = {
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "";
    };
    # doom-config = {
    #   url = "...";
    #   flake = false;
    # };
  };
  lix.doomacs = {
    provides.to-hosts.nixos = { pkgs, ... }: {
      nix.settings = {
        substituters = [ "https://doom-emacs-unstraightened.cachix.org" ];
        trusted-substituters = [ "https://doom-emacs-unstraightened.cachix.org" ];
        trusted-public-keys = [
          "doom-emacs-unstraightened.cachix.org-1:O5oOlRPnmQEvVaFyuMTmthCEooHbrg54WgSLR07tmg4="
        ];
        trusted-users = [
          "root"
          "@wheel"
        ];
      };
      # make magit works
      environment.systemPackages = with pkgs; [
        git
      ];
    };
    homeManager = { pkgs, ... }: {
      imports = [ inputs.nix-doom-emacs-unstraightened.homeModule ];
      services.emacs.enable = true;
      programs.doom-emacs = {
        enable = true;
        # Skip per-package .eln (native-comp) build step for faster rebuilds.
        # See https://github.com/nix-community/emacs-overlay/issues/369#issuecomment-4427696458
        emacs = pkgs.emacs.overrideAttrs (old: {
          passthru = old.passthru // {
            withNativeCompilation = false;
          };
        });
        # doomDir = inputs.doom-config;
        doomDir = ./_doomdir;
        tangleArgs = "--all config.org";
        extraPackages =
          epkgs: with epkgs; [
            eglot
            treesit-grammars.with-all-grammars
          ];
      };
      home.packages =
        with pkgs;
        [
          (pkgs.aspellWithDicts (dicts: [
            dicts.en
            dicts.en-computers
          ]))
          languagetool
          nerd-fonts.symbols-only
          fd
          ripgrep
          nodejs
          wmctrl
          xdotool
          aria
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
        ]
    };
  };
}
