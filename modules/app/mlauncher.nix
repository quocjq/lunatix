{
  __findFile,
  inputs,
  ...
}: {
  flake-file.inputs.fjordlauncher = {
    url = "github:unmojang/FjordLauncher";
  };
  lix.mlauncher = {
    os = {pkgs, ...}: {
      # environment.systemPackages = [inputs.fjordlauncher.packages.${pkgs.stdenv.hostPlatform.system}.fjordlauncher];
      # programs.nix-ld = {
      #   enable = true;
      #   libraries = with pkgs; [
      #     libglvnd
      #   ];
      # };
      services.flatpak.enable = true;
    };
    maid = {
      file.home.".local/share/Fjordlauncher/accounts.json" = {
        source = "{{home}}/config/.local/share/Fjordlauncher/accounts.json";
      };
    };
  };
}
