{ inputs, ... }:
{
  flake-file.inputs = {
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "";
    };
    doom-config = {
      url = "github:quocjq/doomdir";
      flake = false;
    };
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
      # HACK: make magit works
      environment.systemPackages = with pkgs; [
        git
      ];
    };
    homeManager = { pkgs, ... }: {
      imports = [ inputs.nix-doom-emacs-unstraightened.homeModule ];
      services.emacs.enable = true;
      programs.doom-emacs = {
        enable = true;
        doomDir = inputs.doom-config;
        tangleArgs = "--all config.org";
        extraPackages =
          epkgs: with epkgs; [
            eglot
            vterm
            nix-ts-mode
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
        hugo
        dockfmt
        html-tidy
        universal-ctags
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

        # Nix
        nil # nix language server
        nixd
        nixfmt
        nixfmt-tree
        deadnix
        nixpkgs-review

        # lisp
        sbcl

        # Rust
        cargo
        rustc
        rustfmt
        clippy
        rust-analyzer
      ];
    };
  };
}
