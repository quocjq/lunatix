{
  den,
  inputs,
  ...
}: {
  imports = [
    (inputs.flake-file.flakeModules.dendritic or {})
    (inputs.den.flakeModules.dendritic or {})
    (inputs.agenix-rekey.flakeModules.default or {})
  ];
  _module.args.__findFile = den.lib.__findFile;

  # other inputs may be defined at a module using them.
  flake-file.inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    den.url = "github:denful/den";
    den-diagram = {
      url = "github:denful/den-diagram";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.url = "github:denful/flake-file";
    nix-maid = {
      url = "git+https://codeberg.org/viperML/nix-maid";
    };
    devenv.url = "github:cachix/devenv";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
