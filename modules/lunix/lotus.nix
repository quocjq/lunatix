{ inputs, ... }:
{
  # `flake-file` reads `flake-file.inputs.X` from across the repo and merges
  # them into the top-level `inputs` attr of flake.nix on regeneration.
  flake-file.inputs.lotus = {
    url = "github:lotusinputmethod/fcitx5-lotus";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  lix.lotus = {
    provides.to-hosts.nixos = { pkgs, ... }: {
      imports = [ inputs.lotus.nixosModules.fcitx5-lotus ];

      # The upstream module defaults to `inputs.self.packages.<sys>.fcitx5-lotus`,
      # which is undefined when the flake is consumed externally. Pin it here.
      services.fcitx5-lotus = {
        enable = true;
        package = inputs.lotus.packages.${pkgs.stdenv.hostPlatform.system}.fcitx5-lotus;
        users = [ "lunixose" ];
      };

      # Wire up the fcitx5 framework + session env vars (XMODIFIERS / GTK_IM_MODULE /
      # QT_IM_MODULE / INPUT_METHOD). The lotus module only adds itself to the addon list.
      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
      };
    };

    provides.to-hosts.homeManager = { ... }: {
      # Same env-var wiring for the Hyprland session (no DM, so the NixOS-level
      # i18n vars don't reach Hyprland directly).
      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
      };
    };
  };
}
