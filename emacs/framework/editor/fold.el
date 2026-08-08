;;; editor/fold.el --- doom editor/fold port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/editor/fold.
;;; Code:

;;; Fold (doom editor/fold)
(leaf vimish-fold
  :ensure t
  :defer t
  :config
  (vimish-fold-mode 1))

(leaf evil-vimish-fold
  :ensure t
  :after vimish-fold
  :config
  (evil-vimish-fold-mode 1))

;;; editor/fold.el ends here
