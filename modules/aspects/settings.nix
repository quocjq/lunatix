{ ... }:
{
  den.aspects.settings = {
    nixos = { pkgs, ... }: {
      networking.networkmanager.enable = true;

      time.timeZone = "Asia/Ho_Chi_Minh";

      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "vi_VN";
        LC_IDENTIFICATION = "vi_VN";
        LC_MEASUREMENT = "vi_VN";
        LC_MONETARY = "vi_VN";
        LC_NAME = "vi_VN";
        LC_NUMERIC = "vi_VN";
        LC_PAPER = "vi_VN";
        LC_TELEPHONE = "vi_VN";
        LC_TIME = "vi_VN";
      };

      services.xserver.enable = true;
      services.displayManager.sddm.enable = true;
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };
      fonts.packages = with pkgs; [
        jetbrains-mono
        fira-code
        symbola
        nerd-fonts.jetbrains-mono
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ];

      services.printing.enable = true;

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      programs.firefox.enable = true;

      nixpkgs.config.allowUnfree = true;

      environment.systemPackages = with pkgs; [
        neovim
        wget
        git
        curl
        obsidian
      ];
    };
  };
}
