{
  den.aspects.nixcord.config = {
    programs.nixcord = {
      quickCss = "/* css goes here */";
      config = {
        useQuickCss = true;
        enabledThemeLinks = [
          "https://raw.githubusercontent.com/Catppuccin/discord/main/themes/mocha.theme.css"
        ];
        frameless = true;
        transparent = true;

        plugins = {
          clearUrls.enable = true;
          fakeProfileThemes.enable = true;
          noF1.enable = true;
          hideMedia.enable = true;
          ignoreActivities = {
            enable = true;
            ignorePlaying = true;
          };
        };
      };
    };
  };
}
