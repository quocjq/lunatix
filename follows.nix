{
  # Per-input sub-input follows declarations.
  #
  # Mirrors the inputs.X.inputs.Y.follows block from the original flake.nix.
  # Each top-level entry maps input name -> spec, where spec has the shape:
  #   { inputs.Y.follows = "Z"; }      sub-input Y follows top-level input Z
  #   { inputs = { Y.follows = "Z"; }; }  same, deeper syntax
  #
  # `with-inputs` reads this to override the default sub-input resolution
  # when assembling the inputs attrset.
  agenix = {
    inputs = {
      nixpkgs.follows = "nixpkgs";
      home-manager.follows = "home-manager";
    };
  };
  flake-parts = {
    inputs.nixpkgs-lib.follows = "nixpkgs";
  };
  plasma-manager = {
    inputs = {
      nixpkgs.follows = "nixpkgs";
      home-manager.follows = "home-manager";
    };
  };
  nix-doom-emacs-unstraightened = {
    # Intentionally does not follow nixpkgs.
    inputs.nixpkgs.follows = "";
  };
}