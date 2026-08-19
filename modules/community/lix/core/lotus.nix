{
  inputs,
  ...
}:
{
  # `flake-file` reads `flake-file.inputs.X` from across the repo and merges
  # them into the top-level `inputs` attr of flake.nix on regeneration.
  flake-file.inputs.lotus = {
    url = "github:lotusinputmethod/fcitx5-lotus";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  lix.lotus = {
    os = { pkgs, ... }: {
      imports = [ inputs.lotus.nixosModules.fcitx5-lotus ];
      services.fcitx5-lotus = {
        enable = true;
        package = inputs.lotus.packages.${pkgs.stdenv.hostPlatform.system}.fcitx5-lotus;
        users = [ "lunixose" ];
      };

      # fcitx5 engine: the old home-manager `i18n.inputMethod.fcitx5.settings`
      # (hotkeys/behavior/groups) is frozen into ~/.config/fcitx5 by nix-maid.
      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          waylandFrontend = true;
          addons = [
            inputs.lotus.packages.${pkgs.stdenv.hostPlatform.system}.fcitx5-lotus
          ];
        };
      };
    };

    maid = {
      file.xdg_config."fcitx5".source = ./_config/.config/fcitx5;
    };
  };
}
