{ __findFile, inputs, ... }: {
  flake-file.inputs.herdr = {
    url = "github:ogulcancelik/herdr";
  };
  lix.herdr = {
    os = { pkgs, ... }: {
      environment.systemPackages = [
        inputs.herdr.packages.${pkgs.system}.default
      ];
    };
  };
}
