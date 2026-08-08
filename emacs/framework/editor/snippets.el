;;; editor/snippets.el --- doom editor/snippets port  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Ported from doom-modules/modules/editor/snippets.
;;; Code:

;;; Snippets (doom editor/snippets)
(leaf yasnippet
  :ensure t
  :defer t
  :hook (prog-mode . yas-minor-mode)
  :config
  (yas-reload-all))

(leaf yasnippet-snippets
  :ensure t
  :after yasnippet)

(leaf auto-yasnippet
  :ensure t
  :defer t)

;;; editor/snippets.el ends here
