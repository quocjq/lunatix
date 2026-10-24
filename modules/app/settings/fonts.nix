{
  den.aspects.fonts = {
    nixos = { pkgs, ... }: {
      fonts.packages = with pkgs; [
        jetbrains-mono
        fira-code
        nerd-fonts.jetbrains-mono
        nerd-fonts.symbols-only
        nerd-fonts.jetbrains-mono
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ];
    };
  };
}
