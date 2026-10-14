{ __findFile, inputs, ... }: {

  flake-file.inputs.prismlauncher = {
    url = "github:PrismLauncher/PrismLauncher/refs/tags/9.2";
  };
  lix.prismlauncher = {
    os = { pkgs, ... }: {
      environment.systemPackages = [ inputs.prismlauncher.packages.${pkgs.system}.prismlauncher ];
    };
  };
}
