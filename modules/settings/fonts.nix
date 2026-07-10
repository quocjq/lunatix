{
  den.aspects.fonts = {
    nixos = { pkgs, ... }: {
      fonts.packages = with pkgs; [
        jetbrains-mono
        fira-code
        symbola
        nerd-fonts.jetbrains-mono
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ];
    };
  };
}
