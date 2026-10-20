# DO-NOT-EDIT. This file was auto-generated using github:denful/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    agenix.url = "github:ryantm/agenix";
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blog = {
      type = "git";
      url = "git+https://git.lunixose.duckdns.org/lunixose/blog";
    };
    caelestia.url = "github:caelestia-dots/shell";
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
    import-tree.url = "github:denful/import-tree";
    lotus = {
      url = "github:lotusinputmethod/fcitx5-lotus";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-maid.url = "git+https://codeberg.org/viperML/nix-maid";
    nixcord.url = "github:4evy/nixcord";
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    prismlauncher.url = "github:PrismLauncher/PrismLauncher/refs/tags/9.2";
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
