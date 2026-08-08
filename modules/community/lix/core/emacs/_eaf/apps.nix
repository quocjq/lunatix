# EAF app set shared by ./eaf.nix (perSystem iteration target) and ./emacs.nix
# (home-manager extraPackages). `eaf-file-manager` is deliberately disabled.
s: with s; [
  eaf-browser
  eaf-pdf-viewer
  eaf-image-viewer
]
