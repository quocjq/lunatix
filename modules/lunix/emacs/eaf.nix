{
  lix.doomacs = {
    homeManager = { pkgs }: {
      programs.doom-emacs = {
        extraPackages =
          epkgs: with epkgs; [
            emacs-application-framework
            eaf-file-manager
            eaf-browser
            eaf-pdf-viewer
            eaf-pdf-viewer
          ];
      };
      home.packages = with pkgs.python314Packages; [
        pandas
        requests
        sexpdata
        tld
        pyqt6
        pyqt6-sip
        pyqt6-webengine
        epc
        lxml # for eaf
        qrcode # eaf-file-browser
        pysocks # eaf-browser
        pymupdf # eaf-pdf-viewer
        pypinyin # eaf-file-manager
        psutil # eaf-system-monitor
        retry # eaf-markdown-previewer
        markdown
      ];
    };
  };
}
