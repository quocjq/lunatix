# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blog = {
      type = "tarball";
      url = "https://git.lunixose.duckdns.org/lunixose/blog/archive/main.tar.gz";
    };
    den.url = "github:denful/den";
    den-diagram = {
      url = "github:denful/den-diagram";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv.url = "github:cachix/devenv";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    eaf = {
      url = "github:emacs-eaf/emacs-application-framework";
      flake = false;
    };
    eaf-browser = {
      url = "github:emacs-eaf/eaf-browser";
      flake = false;
    };
    eaf-file-manager = {
      url = "github:emacs-eaf/eaf-file-manager";
      flake = false;
    };
    eaf-image-viewer = {
      url = "github:emacs-eaf/eaf-image-viewer";
      flake = false;
    };
    eaf-pdf-viewer = {
      url = "github:emacs-eaf/eaf-pdf-viewer";
      flake = false;
    };
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.url = "github:denful/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    herdr.url = "github:ogulcancelik/herdr";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homepage = {
      type = "git";
      url = "git+https://git.lunixose.duckdns.org/lunixose/homepage";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    import-tree.url = "github:vic/import-tree";
    lnav = {
      url = "github:quocjq/lnav";
      flake = false;
    };
    lotus = {
      url = "github:lotusinputmethod/fcitx5-lotus";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixcord.url = "github:4evy/nixcord";
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        tinted-schemes.follows = "tinted-schemes";
      };
    };
    tinted-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
